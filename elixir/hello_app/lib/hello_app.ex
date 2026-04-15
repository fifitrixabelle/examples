defmodule HelloApp do
  @moduledoc """
  Documentation for `HelloApp`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> HelloApp.hello()
      :world

  """
  def hello do
    :world
  end

  @doc """
  Returns a personalized greeting.

  ## Examples

      iex> HelloApp.greet("Fifi")
      "Hello, Fifi!"
  """
  def greet(name) when is_binary(name) do
    "Hello, #{name}!"
  end

  @emojis [
    "😀",
    "😃",
    "😄",
    "😁",
    "😆",
    "😅",
    "😂",
    "🤣",
    "🥲",
    "😊",
    "😇",
    "🙂",
    "🙃",
    "😉",
    "😌",
    "😍",
    "🥰",
    "😘",
    "😗",
    "😙",
    "😚",
    "😋",
    "😛",
    "😜",
    "🤪",
    "😝",
    "🤑",
    "🤗",
    "🤭",
    "🤫",
    "🤔",
    "🫡",
    "🤤",
    "😴",
    "😎",
    "🤓",
    "🧐",
    "😏",
    "😒",
    "🙄",
    "😬",
    "🤥",
    "😶‍🌫️",
    "🥳",
    "😻",
    "😼",
    "😽",
    "🙀",
    "😿",
    "😾",
    "🦄",
    "🐶",
    "🐱",
    "🐭",
    "🐹",
    "🐰",
    "🦊",
    "🐻",
    "🐼",
    "🐨",
    "🐯",
    "🦁",
    "🐮",
    "🐷",
    "🐸",
    "🐵",
    "🙈",
    "🙉",
    "🙊",
    "🐔",
    "🐧",
    "🐦",
    "🦉",
    "🦅",
    "🦇",
    "🐺",
    "🐗",
    "🐴",
    "🦓",
    "🦒",
    "🦘",
    "🦥",
    "🦦",
    "🦨",
    "🦔",
    "🐙",
    "🦑",
    "🦐",
    "🦞",
    "🦀",
    "🐡",
    "🐠",
    "🐟",
    "🐬",
    "🐳",
    "🐋",
    "🦈",
    "🐊",
    "🐢",
    "🐍",
    "🦎",
    "🦂",
    "🕷️",
    "🕸️",
    "🦗",
    "🪲",
    "🪳",
    "🪰",
    "🪱",
    "🦋",
    "🌸",
    "🌼",
    "🌻",
    "🌺",
    "🌹",
    "🥀",
    "🌷",
    "🌱",
    "🌲",
    "🌳",
    "🌴",
    "🌵",
    "🌾",
    "🌿",
    "☘️",
    "🍀",
    "🍁",
    "🍂",
    "🍃",
    "🍄",
    "🍇",
    "🍉",
    "🍊",
    "🍋",
    "🍌",
    "🍍",
    "🥭",
    "🍎",
    "🍏",
    "🍐",
    "🍑",
    "🍒",
    "🍓",
    "🥝",
    "🍅",
    "🥥",
    "🥦",
    "🥕",
    "🌽",
    "🥔",
    "🥟",
    "🍢",
    "🍡",
    "🍧",
    "🍨",
    "🍦",
    "🥧",
    "🍰",
    "🎂",
    "🧁",
    "🍮",
    "🍭",
    "🍬",
    "🍫",
    "🍿",
    "🍩",
    "🍪",
    "☕️",
    "🍵",
    "🥤",
    "🧋",
    "🍺",
    "🍻",
    "🍷",
    "🍸",
    "🍹",
    "🍾",
    "🥂",
    "🥃",
    "🍶",
    "🧃",
    "🧊",
    "🎈",
    "🎉",
    "🎊",
    "🎮",
    "🎲",
    "🎯",
    "🎳",
    "🎰",
    "🎵",
    "🎶",
    "🎼",
    "🎷",
    "🎺",
    "🎸",
    "🎹",
    "🎻",
    "🥁",
    "🪘",
    "🪇",
    "🪈",
    "🪕",
    "🎬",
    "🎨",
    "🧠",
    "⚡️",
    "🔥",
    "🌟",
    "⭐️"
  ]
  @colors [:red, :green, :yellow, :blue, :magenta, :cyan]

  @doc """
  Lists emojis that can be used in random greetings.
  """
  def emojis, do: @emojis

  @doc """
  Lists ANSI colors that can be used in random greetings.
  """
  def colors, do: @colors

  @doc """
  Builds a random colored greeting tuple.

  Returns `{color, emoji, message}` where `color` is an ANSI color atom,
  `emoji` is one of the configured emojis, and `message` includes both the
  emoji and the provided `name`.
  """
  def random_colored_greeting(name \\ "friend") when is_binary(name) do
    emoji = Enum.random(@emojis)
    color = Enum.random(@colors)
    message = "#{emoji} Hello, #{name}!"

    {color, emoji, message}
  end

  @doc """
  Prints a random colored greeting to standard output.
  """
  def print_random(name \\ "friend") when is_binary(name) do
    {color, _emoji, message} = random_colored_greeting(name)

    formatted = IO.ANSI.format([color, message, :reset]) |> IO.iodata_to_binary()
    IO.puts(formatted)

    :ok
  end

  @doc """
  Builds a block of random colored emojis and text as a string.
  """
  def random_colored_block(rows \\ 5, columns \\ 10)
      when is_integer(rows) and rows > 0 and is_integer(columns) and columns > 0 do
    for _row <- 1..rows do
      for _col <- 1..columns do
        color = Enum.random(@colors)
        emoji = Enum.random(@emojis)
        IO.ANSI.format([color, emoji, :reset]) |> IO.iodata_to_binary()
      end
      |> Enum.join(" ")
    end
    |> Enum.join("\n")
  end

  @doc """
  Prints a block of random colored emojis and text.
  """
  def print_random_block(rows \\ 5, columns \\ 10)
      when is_integer(rows) and rows > 0 and is_integer(columns) and columns > 0 do
    random_colored_block(rows, columns)
    |> IO.puts()

    :ok
  end

  @doc """
  Animates random colored emoji blocks in the terminal.

  Options:
    * `:delay` — delay in milliseconds between frames (default `200`)
    * `:iterations` — number of frames to render (default `:infinity`)
    * `:size_fun` — function returning `{rows, columns}` for each frame
    * `:rows` / `:columns` — fixed grid overrides (fallback if provided)
  """
  def animate_random_block(opts \\ []) when is_list(opts) do
    delay = Keyword.get(opts, :delay, 200)
    iterations = Keyword.get(opts, :iterations, :infinity)

    size_fun =
      case {Keyword.get(opts, :rows), Keyword.get(opts, :columns)} do
        {r, c} when is_integer(r) and r > 0 and is_integer(c) and c > 0 ->
          fn -> {r, c} end

        {nil, nil} ->
          Keyword.get(opts, :size_fun, &fetch_terminal_size/0)

        _ ->
          raise ArgumentError, "`:rows` and `:columns` must both be positive integers"
      end

    do_animate_random_block(size_fun, delay, iterations)
  end

  defp do_animate_random_block(size_fun, delay, :infinity) when is_function(size_fun, 0) do
    render_frame(size_fun)
    Process.sleep(max(delay, 0))
    do_animate_random_block(size_fun, delay, :infinity)
  end

  defp do_animate_random_block(size_fun, delay, iterations)
       when is_function(size_fun, 0) and is_integer(iterations) and iterations > 0 do
    render_frame(size_fun)
    Process.sleep(max(delay, 0))
    do_animate_random_block(size_fun, delay, iterations - 1)
  end

  defp do_animate_random_block(_size_fun, _delay, iterations)
       when is_integer(iterations) and iterations <= 0 do
    :ok
  end

  defp render_frame(size_fun) do
    {rows, columns} = size_fun.()
    IO.write(IO.ANSI.home() <> IO.ANSI.clear())
    IO.puts(random_colored_block(rows, columns))
  end

  defp fetch_terminal_size do
    columns =
      case :io.columns() do
        {:ok, count} when is_integer(count) and count > 0 -> count
        _ -> 80
      end

    rows =
      case :io.rows() do
        {:ok, count} when is_integer(count) and count > 0 -> count
        _ -> 24
      end

    {rows, columns}
  end
end
