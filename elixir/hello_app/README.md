# HelloApp

HelloApp is a tiny Elixir playground for building joyful greetings. It offers
helpers for returning atoms, strings, and ANSI colored output so you can greet
someone by name, spray the terminal with emoji blocks, or even animate a stream
of random colors.

## Features

- **Greeting helpers:** Return `:world`, a personalized string, or prebuilt
tuples containing ANSI color metadata.
- **Emoji catalog:** Access an ever-growing list of emoji choices via
  `HelloApp.emojis/0`.
- **Color aware output:** Print colorful greetings or emoji grids to the
  terminal with `HelloApp.print_random/1` and `HelloApp.print_random_block/2`.
- **Terminal animation:** Render continuously updating emoji blocks with
  `HelloApp.animate_random_block/1`.

## Getting Started

```bash
mix deps.get
mix compile
```

Launch an IEx session with the project loaded:

```bash
iex -S mix
```

## Usage

```elixir
iex> HelloApp.hello()
:world

iex> HelloApp.greet("Fifi")
"Hello, Fifi!"

iex> HelloApp.random_colored_greeting("Sam")
{:green, "😄", "😄 Hello, Sam!"}

iex> HelloApp.print_random("Taylor")
:ok

iex> HelloApp.print_random_block(3, 5)
:ok

iex> HelloApp.animate_random_block(delay: 100, iterations: 10)
:ok
```

Pass `:rows` and `:columns` options to fix the grid size, or provide a
`:size_fun` callback to control each animation frame.

## Installation

If [available in Hex](https://hex.pm/docs/publish), add `hello_app` to your
project dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hello_app, "~> 0.1.0"}
  ]
end
```

## Development

Run the test suite to verify changes:

```bash
mix test
```

Documentation can be generated with
[ExDoc](https://github.com/elixir-lang/ex_doc) and published on
[HexDocs](https://hexdocs.pm). Once published, the docs will be available at
<https://hexdocs.pm/hello_app>.
