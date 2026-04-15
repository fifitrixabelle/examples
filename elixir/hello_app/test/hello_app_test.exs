defmodule HelloAppTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  doctest HelloApp

  test "greets the world" do
    assert HelloApp.hello() == :world
  end

  test "builds a random colored greeting with known values" do
    {color, emoji, message} = HelloApp.random_colored_greeting("Fifi")

    assert color in HelloApp.colors()
    assert emoji in HelloApp.emojis()
    assert String.contains?(message, emoji)
    assert String.contains?(message, "Fifi")
  end

  test "prints a random colored greeting" do
    output = capture_io(fn -> HelloApp.print_random("Fifi") end)

    assert String.contains?(output, "Fifi")
  end

  test "builds a random colored block" do
    block = HelloApp.random_colored_block(2, 3)
    lines = String.split(block, "\n")

    assert length(lines) == 2
    assert Enum.all?(lines, fn line -> length(String.split(line, " ")) == 3 end)
    assert Enum.any?(HelloApp.emojis(), &String.contains?(block, &1))
  end

  test "prints a random colored block" do
    output = capture_io(fn -> HelloApp.print_random_block(2, 2) end)
    lines = output |> String.trim_trailing() |> String.split("\n")

    assert length(lines) == 2
    assert Enum.any?(HelloApp.emojis(), &String.contains?(output, &1))
  end

  test "animates random colored block for finite iterations" do
    separator = IO.ANSI.home() <> IO.ANSI.clear()

    output =
      capture_io(fn ->
        HelloApp.animate_random_block(delay: 0, iterations: 2, size_fun: fn -> {2, 2} end)
      end)

    frames = output |> String.split(separator, trim: true)

    assert length(frames) == 2
    assert Enum.any?(HelloApp.emojis(), &String.contains?(output, &1))
  end
end
