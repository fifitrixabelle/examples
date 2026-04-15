defmodule Style do
  def paint(code, text), do: "\e[#{code}m#{text}\e[0m"
  def meter(value), do: String.duplicate("▰", max(1, div(value, 2)))
end

defmodule Dancer do
  def start(name, color, pattern, controller) do
    spawn(fn ->
      Enum.with_index(pattern, 1)
      |> Enum.each(fn {energy, beat} ->
        send(controller, {:pulse, %{name: name, color: color, beat: beat, energy: energy}})
      end)
    end)
  end
end

lanes = [
  {"laser", 36, [3, 5, 7, 8, 6, 4, 7, 5]},
  {"glitter", 35, [4, 4, 6, 7, 5, 3, 6, 8]},
  {"echo", 33, [2, 3, 5, 6, 6, 5, 4, 5]}
]

controller = self()
Enum.each(lanes, fn {name, color, pattern} -> Dancer.start(name, color, pattern, controller) end)

timeline =
  Enum.reduce(1..(length(lanes) * 8), %{}, fn _, acc ->
    receive do
      {:pulse, pulse} ->
        Map.update(acc, pulse.beat, [pulse], &[pulse | &1])
    end
  end)

IO.puts(Style.paint(35, "════════ Elixir Pulse Relay 🎡 ════════"))
IO.puts(Style.paint(33, "  processes toss beat packets to a tiny controller"))
IO.puts("")

Enum.each(1..8, fn beat ->
  row =
    timeline
    |> Map.get(beat, [])
    |> Enum.sort_by(& &1.name)

  cells =
    Enum.map_join(row, "  ", fn pulse ->
      glyph =
        cond do
          pulse.energy >= 7 -> "◆"
          pulse.energy >= 5 -> "▲"
          pulse.energy >= 3 -> "■"
          true -> "·"
        end

      Style.paint(pulse.color, "#{glyph} #{pulse.name}")
    end)

  crowd = Enum.reduce(row, 0, fn pulse, sum -> sum + pulse.energy end)
  IO.puts("  #{Style.paint(1, "beat #{String.pad_leading(Integer.to_string(beat), 2, "0")}")}  #{cells}  crowd=#{Style.paint(32, Style.meter(crowd))}")
end)
