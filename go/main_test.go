package main

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestNormalizeDBName(t *testing.T) {
	oldDir := databaseDir
	tmp := t.TempDir()
	databaseDir = tmp
	t.Cleanup(func() { databaseDir = oldDir })

	base, full, err := normalizeDBName("example")
	if err != nil {
		t.Fatalf("normalizeDBName unexpected error: %v", err)
	}
	if base != "example"+defaultDBExtension {
		t.Fatalf("expected base %q, got %q", "example"+defaultDBExtension, base)
	}
	expectedFull := filepath.Join(tmp, base)
	if full != expectedFull {
		t.Fatalf("expected full path %q, got %q", expectedFull, full)
	}

	cases := []string{"", "../../etc/passwd", "bad/sep", "name?"}
	for _, name := range cases {
		if _, _, err := normalizeDBName(name); err == nil {
			t.Fatalf("expected error for name %q", name)
		}
	}

	base, _, err = normalizeDBName("custom.db")
	if err != nil {
		t.Fatalf("normalizeDBName with extension error: %v", err)
	}
	if base != "custom.db" {
		t.Fatalf("expected base to preserve extension, got %q", base)
	}
}

func TestIsSupportedDB(t *testing.T) {
	if !isSupportedDB("file.duckdb") {
		t.Fatalf("expected duckdb extension to be supported")
	}
	if !isSupportedDB("file.DB") {
		t.Fatalf("expected db extension (case-insensitive) to be supported")
	}
	if isSupportedDB("file.sqlite") {
		t.Fatalf("did not expect sqlite extension to be supported")
	}
}

func TestHumanSize(t *testing.T) {
	tests := []struct {
		size     int64
		expected string
	}{
		{5, "5B"},
		{1<<10 + 1, "1.0k"},
		{1<<20 + 1, "1.0M"},
		{1<<30 + 1, "1.0G"},
	}
	for _, tt := range tests {
		if got := humanSize(tt.size); got != tt.expected {
			t.Fatalf("humanSize(%d) = %q, want %q", tt.size, got, tt.expected)
		}
	}
}

func TestRenderInput(t *testing.T) {
	if got := renderInput(""); got != "_" {
		t.Fatalf("renderInput empty expected '_', got %q", got)
	}
	if got := renderInput("foo"); got != "foo_" {
		t.Fatalf("renderInput \"foo\" expected 'foo_', got %q", got)
	}
}

func TestIsAllowedRune(t *testing.T) {
	if !isAllowedRune('a') || !isAllowedRune('-') {
		t.Fatalf("expected alphanumeric and dash to be allowed")
	}
	if isAllowedRune('!') {
		t.Fatalf("expected '!' to be disallowed")
	}
}

func TestListDatabases(t *testing.T) {
	oldDir := databaseDir
	tmp := t.TempDir()
	databaseDir = tmp
	t.Cleanup(func() { databaseDir = oldDir })

	mustWrite := func(name string) {
		path := filepath.Join(tmp, name)
		if err := os.WriteFile(path, []byte("data"), 0o644); err != nil {
			t.Fatalf("write file %s: %v", name, err)
		}
		if err := os.Chtimes(path, time.Now(), time.Now()); err != nil {
			t.Fatalf("chtimes %s: %v", name, err)
		}
	}

	mustWrite("bbb.duckdb")
	mustWrite("aaa.db")
	_ = os.WriteFile(filepath.Join(tmp, "ignore.txt"), []byte("noop"), 0o644)
	if err := os.Mkdir(filepath.Join(tmp, "subdir"), 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}

	entries, err := listDatabases()
	if err != nil {
		t.Fatalf("listDatabases error: %v", err)
	}
	if len(entries) != 2 {
		t.Fatalf("expected 2 entries, got %d", len(entries))
	}
	if entries[0].Name != "aaa.db" || entries[1].Name != "bbb.duckdb" {
		t.Fatalf("expected alphabetical ordering, got %q then %q", entries[0].Name, entries[1].Name)
	}
}
