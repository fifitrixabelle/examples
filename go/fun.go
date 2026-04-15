package main

import (
	"fmt"
	"sort"
	"strings"
	"sync"
)

const (
	reset   = "\x1b[0m"
	bold    = "\x1b[1m"
	magenta = "\x1b[35m"
	cyan    = "\x1b[36m"
	yellow  = "\x1b[33m"
	green   = "\x1b[32m"
	blue    = "\x1b[34m"
)

type pulse struct {
	Beat   int
	Lane   string
	Glyph  string
	Energy int
	Color  string
}

func paint(code, text string) string {
	return code + text + reset
}

func launchLane(name string, color string, seed int, beats int, out chan<- pulse, wg *sync.WaitGroup) {
	defer wg.Done()

	for beat := 0; beat < beats; beat++ {
		energy := ((seed * (beat + 3)) + beat*beat + seed) % 9
		glyph := "·"
		if energy >= 7 {
			glyph = "◆"
		} else if energy >= 5 {
			glyph = "▲"
		} else if energy >= 3 {
			glyph = "■"
		}

		out <- pulse{
			Beat:   beat,
			Lane:   name,
			Glyph:  glyph,
			Energy: energy,
			Color:  color,
		}
	}
}

func meter(values []int) string {
	blocks := strings.Builder{}
	for _, value := range values {
		switch {
		case value >= 7:
			blocks.WriteString("█")
		case value >= 5:
			blocks.WriteString("▆")
		case value >= 3:
			blocks.WriteString("▄")
		case value >= 1:
			blocks.WriteString("▂")
		default:
			blocks.WriteString("·")
		}
	}
	return blocks.String()
}

func main() {
	beats := 16
	lanes := []struct {
		Name  string
		Color string
		Seed  int
	}{
		{Name: "laser", Color: cyan, Seed: 3},
		{Name: "glow", Color: yellow, Seed: 5},
		{Name: "drift", Color: green, Seed: 7},
		{Name: "echo", Color: blue, Seed: 11},
	}

	out := make(chan pulse, len(lanes)*beats)
	var wg sync.WaitGroup
	for _, lane := range lanes {
		wg.Add(1)
		go launchLane(lane.Name, lane.Color, lane.Seed, beats, out, &wg)
	}

	go func() {
		wg.Wait()
		close(out)
	}()

	timeline := map[int][]pulse{}
	laneEnergy := map[string][]int{}
	for item := range out {
		timeline[item.Beat] = append(timeline[item.Beat], item)
		laneEnergy[item.Lane] = append(laneEnergy[item.Lane], item.Energy)
	}

	fmt.Println(paint(magenta, "======== Go Channel Arcade ========"))
	fmt.Println("  " + paint(cyan, "goroutines") + " tossing pulses into a shared control bus")
	fmt.Println()

	for beat := 0; beat < beats; beat++ {
		frame := timeline[beat]
		sort.Slice(frame, func(i, j int) bool { return frame[i].Lane < frame[j].Lane })

		var cells []string
		totalEnergy := 0
		for _, item := range frame {
			totalEnergy += item.Energy
			cells = append(cells, paint(item.Color, item.Glyph+" "+item.Lane))
		}

		fmt.Printf("%s beat %02d  %s  crowd=%s\n",
			paint(bold, ">>"),
			beat,
			strings.Join(cells, "  "),
			paint(yellow, strings.Repeat("▰", max(1, totalEnergy/6))),
		)
	}

	fmt.Println()
	fmt.Println("  lane memory:")
	names := make([]string, 0, len(laneEnergy))
	for name := range laneEnergy {
		names = append(names, name)
	}
	sort.Strings(names)
	for _, name := range names {
		color := cyan
		for _, lane := range lanes {
			if lane.Name == name {
				color = lane.Color
			}
		}
		fmt.Printf("  %s %s\n", paint(color, name+" "), paint(color, meter(laneEnergy[name])))
	}
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
