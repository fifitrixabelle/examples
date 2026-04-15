package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"log"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"syscall"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/charmbracelet/ssh"
	"github.com/charmbracelet/wish"
	wishbubbletea "github.com/charmbracelet/wish/bubbletea"
	wishlog "github.com/charmbracelet/wish/logging"
)

const (
	listenAddr   = ":2323"
	hostKeyPath  = "tmp/wish_demo_ed25519"
	duckDBBinary = "duckdb"
)

var (
	databaseDir        = "data/db"
	defaultDBExtension = ".duckdb"
	supportedExts      = []string{`.duckdb`, `.db`}
	dbNamePattern      = regexp.MustCompile(`^[A-Za-z0-9._-]+$`)
)

type dbEntry struct {
	Name string
	Path string
	Size int64
	Mod  time.Time
}

type mode int

const (
	modeBrowse mode = iota
	modeCreate
	modeConfirmDelete
)

type model struct {
	session  ssh.Session
	renderer *lipgloss.Renderer

	entries  []dbEntry
	selected int
	status   string
	err      error

	width  int
	height int

	styles        uiStyles
	pendingLaunch *dbEntry
	exitRequested bool

	mode        mode
	inputBuffer string
	confirmName string
}

type uiStyles struct {
	title        lipgloss.Style
	subtitle     lipgloss.Style
	panel        lipgloss.Style
	panelTitle   lipgloss.Style
	selectedItem lipgloss.Style
	status       lipgloss.Style
	error        lipgloss.Style
	help         lipgloss.Style
}

func main() {
	if err := os.MkdirAll(databaseDir, 0o755); err != nil {
		log.Fatalf("failed to ensure database directory: %v", err)
	}
	if err := os.MkdirAll(filepath.Dir(hostKeyPath), 0o700); err != nil {
		log.Fatalf("failed to ensure host key directory: %v", err)
	}

	srv, err := wish.NewServer(
		wish.WithAddress(listenAddr),
		wish.WithHostKeyPath(hostKeyPath),
		wish.WithMiddleware(
			wishlog.Middleware(),
			managerMiddleware,
		),
		ssh.AllocatePty(),
	)
	if err != nil {
		log.Fatalf("failed to build SSH server: %v", err)
	}

	log.Printf("Wish DuckDB manager listening on ssh %s", listenAddr)
	log.Println()
	log.Println("🔌 Connect with:")
	log.Printf("  🚀 ssh -p %s charm@localhost\n", strings.TrimPrefix(listenAddr, ":"))
	log.Println("🔁 Auto-reconnect helper:")
	log.Println("  🤖 ./scripts/watch-ssh-client.sh")
	log.Println()

	go func() {
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, ssh.ErrServerClosed) {
			log.Fatalf("ssh server error: %v", err)
		}
	}()

	waitForShutdown(srv)
}

func waitForShutdown(srv *ssh.Server) {
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)
	<-sigCh

	log.Println("shutdown signal received, closing server…")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Printf("graceful shutdown failed: %v", err)
	}
}

func managerMiddleware(next ssh.Handler) ssh.Handler {
	return func(sess ssh.Session) {
		logSessionEvent(sess, "connected")
		defer logSessionEvent(sess, "disconnected")

		if _, _, ok := sess.Pty(); !ok {
			fmt.Fprintln(sess, "This program requires a TTY")
			return
		}

		statusText := ""

		for {
			prog, cancel := newProgram(sess, statusText)
			finalModel, err := prog.Run()
			cancel()
			prog.Kill()
			if err != nil {
				logSessionEvent(sess, "program error: %v", err)
				fmt.Fprintf(sess, "\r\nerror: %v\r\n", err)
				return
			}

			result, ok := finalModel.(model)
			if !ok {
				return
			}

			statusText = result.status

			if result.exitRequested || sess.Context().Err() != nil {
				return
			}

			if result.pendingLaunch != nil {
				entry := *result.pendingLaunch
				if err := runDuckDBShell(sess, entry); err != nil {
					logSessionEvent(sess, "duckdb error: %v", err)
					statusText = fmt.Sprintf("DuckDB error: %v", err)
				} else {
					statusText = fmt.Sprintf("DuckDB session closed for %s", entry.Name)
				}
				continue
			}

			statusText = "Refreshed."
		}
	}
}

func newProgram(sess ssh.Session, status string) (*tea.Program, context.CancelFunc) {
	renderer := wishbubbletea.MakeRenderer(sess)
	if status == "" {
		status = "Welcome! Use ↑/↓ to choose a database. Enter opens, 'n' creates, 'x' deletes."
	}
	mdl := model{
		session:  sess,
		renderer: renderer,
		status:   status,
		styles:   newStyles(renderer),
		mode:     modeBrowse,
	}

	opts := wishbubbletea.MakeOptions(sess)
	if _, _, ok := sess.Pty(); ok {
		opts = append(opts, tea.WithAltScreen())
	}

	program := tea.NewProgram(mdl, opts...)

	ctx, cancel := context.WithCancel(sess.Context())
	if _, winCh, ok := sess.Pty(); ok {
		go func() {
			for {
				select {
				case <-ctx.Done():
					return
				case win, ok := <-winCh:
					if !ok {
						return
					}
					program.Send(tea.WindowSizeMsg{Width: win.Width, Height: win.Height})
				}
			}
		}()
	}

	return program, cancel
}

func newStyles(r *lipgloss.Renderer) uiStyles {
	border := lipgloss.Border{
		Top:         "─",
		Bottom:      "─",
		Left:        "│",
		Right:       "│",
		TopLeft:     "╭",
		TopRight:    "╮",
		BottomLeft:  "╰",
		BottomRight: "╯",
	}
	return uiStyles{
		title:        r.NewStyle().Foreground(lipgloss.Color("205")).Bold(true),
		subtitle:     r.NewStyle().Foreground(lipgloss.Color("81")),
		panel:        r.NewStyle().Border(border).BorderForeground(lipgloss.Color("57")).Padding(1, 2),
		panelTitle:   r.NewStyle().Foreground(lipgloss.Color("45")).Bold(true),
		selectedItem: r.NewStyle().Foreground(lipgloss.Color("229")).Background(lipgloss.Color("57")),
		status:       r.NewStyle().Foreground(lipgloss.Color("112")),
		error:        r.NewStyle().Foreground(lipgloss.Color("197")).Bold(true),
		help:         r.NewStyle().Foreground(lipgloss.Color("244")),
	}
}

func (m model) Init() tea.Cmd {
	return loadDatabasesCmd()
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	case tea.KeyMsg:
		return m.handleKey(msg)
	case dbListMsg:
		if msg.err != nil {
			m.err = msg.err
			m.status = "Failed to load databases"
			logSessionEvent(m.session, "list error: %v", msg.err)
		} else {
			m.err = nil
			m.entries = msg.entries
			if len(m.entries) == 0 {
				m.selected = 0
				m.status = "No databases yet. Press 'n' to create one."
			} else if m.selected >= len(m.entries) {
				m.selected = len(m.entries) - 1
			}
			logSessionEvent(m.session, "loaded %d databases", len(m.entries))
		}

	}
	return m, nil
}

func (m model) View() string {
	var sections []string
	sections = append(sections,
		m.styles.title.Render("🦆 DuckDB Manager"),
		m.styles.subtitle.Render(fmt.Sprintf("Managing files in %s", databaseDir)),
	)

	if m.err != nil {
		sections = append(sections, m.styles.error.Render(fmt.Sprintf("Error: %v", m.err)))
	}
	sections = append(sections, m.styles.status.Render(m.status))
	sections = append(sections, "")

	listPanel := m.styles.panel.Render(m.renderList())
	sections = append(sections, listPanel)

	switch m.mode {
	case modeCreate:
		sections = append(sections, "",
			m.styles.panel.Render(fmt.Sprintf("New database name: %s", renderInput(m.inputBuffer))))
	case modeConfirmDelete:
		sections = append(sections, "",
			m.styles.panel.Render(fmt.Sprintf("Delete %s? (y/N)", m.confirmName)))
	}

	help := "↑/↓ select • Enter open • n new • x delete • r refresh • q quit"
	sections = append(sections, "", m.styles.help.Render(help))

	return lipgloss.JoinVertical(lipgloss.Left, sections...) + "\n"
}

func (m model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch m.mode {
	case modeCreate:
		return m.handleCreateKey(msg)
	case modeConfirmDelete:
		return m.handleConfirmKey(msg)
	}

	if msg.Type == tea.KeyEnter {
		if entry := m.currentEntry(); entry != nil {
			copyEntry := *entry
			m.pendingLaunch = &copyEntry
			m.status = fmt.Sprintf("Launching DuckDB shell for %s…", entry.Name)
			logSessionEvent(m.session, "launching duckdb for %s", entry.Name)
			return m, tea.Quit
		}
		return m, nil
	}

	switch msg.String() {
	case "ctrl+c", "q":
		m.exitRequested = true
		logSessionEvent(m.session, "quit")
		return m, tea.Quit
	case "up", "k":
		if m.selected > 0 {
			m.selected--
		}
	case "down", "j":
		if m.selected < len(m.entries)-1 {
			m.selected++
		}
	case "r":
		m.status = "Refreshing database list…"
		return m, loadDatabasesCmd()
	case "n":
		m.mode = modeCreate
		m.inputBuffer = ""
		m.status = "Enter a name, press Enter to create, Esc to cancel."
	case "x", "delete":
		if entry := m.currentEntry(); entry != nil {
			m.mode = modeConfirmDelete
			m.confirmName = entry.Name
			m.status = fmt.Sprintf("Confirm deletion of %s (y/N)", entry.Name)
		}
	}
	return m, nil
}

func (m model) handleCreateKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.Type {
	case tea.KeyEnter:
		if strings.TrimSpace(m.inputBuffer) == "" {
			m.status = "Name cannot be empty"
			return m, nil
		}
		name := m.inputBuffer
		file, err := createDatabase(name)
		if err != nil {
			m.err = err
			m.status = err.Error()
			logSessionEvent(m.session, "create error for %s: %v", name, err)
			return m, nil
		}
		m.err = nil
		m.mode = modeBrowse
		m.status = fmt.Sprintf("Created %s", file)
		logSessionEvent(m.session, "created %s", file)
		return m, loadDatabasesCmd()
	case tea.KeyEsc:
		m.mode = modeBrowse
		m.status = "Cancelled creation."
		return m, nil
	case tea.KeyBackspace:
		if len(m.inputBuffer) > 0 {
			m.inputBuffer = m.inputBuffer[:len(m.inputBuffer)-1]
		}
	default:
		if len(msg.Runes) == 1 {
			r := msg.Runes[0]
			if isAllowedRune(r) {
				m.inputBuffer += string(r)
			}
		}
	}
	return m, nil
}

func (m model) handleConfirmKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch strings.ToLower(msg.String()) {
	case "y":
		name := m.confirmName
		file, err := deleteDatabase(name)
		m.mode = modeBrowse
		if err != nil {
			m.err = err
			m.status = err.Error()
			logSessionEvent(m.session, "delete error for %s: %v", name, err)
			return m, nil
		}
		m.err = nil
		m.status = fmt.Sprintf("Deleted %s", file)
		logSessionEvent(m.session, "deleted %s", file)
		return m, loadDatabasesCmd()
	case "n", "esc":
		m.mode = modeBrowse
		m.status = "Deletion cancelled."
	}
	return m, nil
}

func (m model) renderList() string {
	if len(m.entries) == 0 {
		return "(no databases yet)"
	}

	rows := make([]string, 0, len(m.entries))
	for i, entry := range m.entries {
		line := fmt.Sprintf("% -20s %8s  %s", entry.Name, humanSize(entry.Size), entry.Mod.Format(time.RFC3339))
		if i == m.selected {
			rows = append(rows, m.styles.selectedItem.Render("▸ "+line))
		} else {
			rows = append(rows, "  "+line)
		}
	}
	return strings.Join(rows, "\n")
}

func (m model) currentEntry() *dbEntry {
	if len(m.entries) == 0 || m.selected < 0 || m.selected >= len(m.entries) {
		return nil
	}
	return &m.entries[m.selected]
}

type dbListMsg struct {
	entries []dbEntry
	err     error
}

func loadDatabasesCmd() tea.Cmd {
	return func() tea.Msg {
		entries, err := listDatabases()
		return dbListMsg{entries: entries, err: err}
	}
}

func runDuckDBShell(sess ssh.Session, entry dbEntry) error {
	if _, err := exec.LookPath(duckDBBinary); err != nil {
		return fmt.Errorf("duckdb CLI not found in PATH")
	}

	cmd := wish.Command(sess, duckDBBinary, entry.Path)
	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return fmt.Errorf("duckdb exited with status %d", exitErr.ExitCode())
		}
		return err
	}

	return nil
}

func listDatabases() ([]dbEntry, error) {
	entries, err := os.ReadDir(databaseDir)
	if err != nil {
		return nil, err
	}
	var out []dbEntry
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if !isSupportedDB(name) {
			continue
		}
		info, err := entry.Info()
		if err != nil {
			return nil, err
		}
		out = append(out, dbEntry{
			Name: name,
			Path: filepath.Join(databaseDir, name),
			Size: info.Size(),
			Mod:  info.ModTime(),
		})
	}
	sort.Slice(out, func(i, j int) bool {
		return strings.ToLower(out[i].Name) < strings.ToLower(out[j].Name)
	})
	return out, nil
}

func createDatabase(name string) (string, error) {
	fileName, fullPath, err := normalizeDBName(name)
	if err != nil {
		return "", err
	}
	if _, err := os.Stat(fullPath); err == nil {
		return "", fmt.Errorf("%s already exists", fileName)
	}
	if _, err := exec.LookPath(duckDBBinary); err != nil {
		return "", fmt.Errorf("duckdb CLI not found in PATH")
	}
	cmd := exec.Command(duckDBBinary, fullPath, "-c", "SELECT 1;")
	if err := cmd.Run(); err != nil {
		if info, statErr := os.Stat(fullPath); statErr == nil && info.Size() > 0 {
			log.Printf("⚠️ duckdb init returned %v but %s now exists", err, fileName)
			return fileName, nil
		}
		_ = os.Remove(fullPath)
		return "", fmt.Errorf("duckdb: %w", err)
	}
	return fileName, nil
}

func deleteDatabase(name string) (string, error) {
	fileName, fullPath, err := normalizeDBName(name)
	if err != nil {
		return "", err
	}
	if err := os.Remove(fullPath); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return "", fmt.Errorf("%s does not exist", fileName)
		}
		return "", err
	}
	return fileName, nil
}

func normalizeDBName(name string) (string, string, error) {
	trimmed := strings.TrimSpace(name)
	if trimmed == "" {
		return "", "", fmt.Errorf("database name cannot be empty")
	}
	base := filepath.Base(trimmed)
	if base != trimmed {
		return "", "", fmt.Errorf("database name cannot contain path separators")
	}
	if !dbNamePattern.MatchString(base) {
		return "", "", fmt.Errorf("invalid name; use letters, numbers, dots, dashes, underscores")
	}
	if filepath.Ext(base) == "" {
		base += defaultDBExtension
	}
	return base, filepath.Join(databaseDir, base), nil
}

func isSupportedDB(name string) bool {
	ext := strings.ToLower(filepath.Ext(name))
	for _, supported := range supportedExts {
		if ext == supported {
			return true
		}
	}
	return false
}

func humanSize(size int64) string {
	switch {
	case size > 1<<30:
		return fmt.Sprintf("%.1fG", float64(size)/(1<<30))
	case size > 1<<20:
		return fmt.Sprintf("%.1fM", float64(size)/(1<<20))
	case size > 1<<10:
		return fmt.Sprintf("%.1fk", float64(size)/(1<<10))
	default:
		return fmt.Sprintf("%dB", size)
	}
}

func renderInput(input string) string {
	if input == "" {
		return "_"
	}
	return input + "_"
}

func isAllowedRune(r rune) bool {
	return dbNamePattern.MatchString(string(r))
}

func logSessionEvent(sess ssh.Session, format string, args ...interface{}) {
	message := fmt.Sprintf(format, args...)
	log.Printf("📝 [%s | %s] %s", sessionLabel(sess), sessionFingerprint(sess), message)
}

func sessionLabel(sess ssh.Session) string {
	return fmt.Sprintf("%s@%s", displayUser(sess), humanRemoteAddr(sess.RemoteAddr()))
}

func displayUser(sess ssh.Session) string {
	if user := strings.TrimSpace(sess.User()); user != "" {
		return user
	}
	return "friend"
}

func humanRemoteAddr(addr net.Addr) string {
	if addr == nil {
		return "unknown"
	}
	return addr.String()
}

func sessionFingerprint(sess ssh.Session) string {
	if pk := sess.PublicKey(); pk != nil {
		hash := sha256.Sum256(pk.Marshal())
		return hex.EncodeToString(hash[:4])
	}
	return "no-key"
}
