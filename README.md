# test

Personal multi-language playground managed with `mise`.

## Languages And Demos

- `go/`: Wish + Charm SSH DuckDB manager (`main.go`) and a small standalone demo (`cmd/fun/main.go`).
- `bun/`: Bun TypeScript demo (`main.ts`).
- `deno/`: Deno TypeScript demo (`main.ts`).
- `crystal/`: Crystal demo (`main.cr`).
- `gleam/`: Gleam demo (`src/gleam_demo.gleam`).
- `python/`: Async RPG CLI + tests, Polars + DuckDB, and marimo app.
- `elixir/hello_app/`: Elixir greeting module + tests + Explorer demo script.
- `ruby/`: Parallel output demo, Sinatra app, and DuckDB + Daru script.
- `rust/`: `hello` bin and `duckdb_polars_demo` bin.
- `raku/`: Main script and test script.
- `zig/`: Zig CLI playground (`main.zig`).
- `lua/`: Lua demo (`main.lua`).
- `clojure/`: Text demo and Tablecloth + DuckDB demo.
- `julia/`: Chaos demo and DuckDB + DataFrames demo.
- `perl/`: Perl demo (`main.pl`).
- `scala/`: Scala CLI demos (`Main.scala`, `duckdb_tablesaw_demo.sc`).

## Quick Start

Run from repo root:

```bash
mise trust
mise install
mise tasks ls
```

Run all default demos:

```bash
mise run
```

Compile the examples that have a real build step:

```bash
mise run build
```

## Task Reference

### Go
```bash
mise run build
mise run go-build
mise run go-fun
mise run go-test
mise run go-main
```

### Bun
```bash
mise run bun-main
```

### Deno
```bash
mise run deno-main
```

### Crystal
```bash
mise run crystal-build
mise run crystal-main
```

### Gleam
```bash
mise run gleam-build
mise run gleam-main
```

### Python
```bash
mise run py-test
mise run py-main
mise run py-polars-duckdb
mise run py-marimo
```

### Elixir
```bash
mise run elixir-build
mise run elixir-test
mise run elixir-explorer
```

### Ruby
```bash
mise run ruby-main
mise run ruby-sinatra
mise run ruby-duckdb-daru
```

### Rust
```bash
mise run rust-build
mise run rust-hello
mise run rust-duckdb-polars
```

### Raku
```bash
mise run raku-main
mise run raku-test
```

### Zig
```bash
mise run zig-build
mise run zig-main
mise run zig-help
```

### Lua
```bash
mise run lua-main
```

### Clojure
```bash
mise run clojure-main
mise run clojure-tablecloth-duckdb
```

### Julia
```bash
mise run julia-main
mise run julia-duckdb-dataframes
```

### Perl
```bash
mise run perl-main
```

### Scala
```bash
mise run scala-build
mise run scala-main
mise run scala-duckdb-tablesaw
```

## Notes

- Tool/runtime versions are pinned in `mise.toml`.
- Some directories contain generated files (`go/tmp/`, `python/.venv/`, `rust/target/`, etc.).
- Build outputs written by `mise run build` land under `tmp/build/`, except for tools that use their native project build directories (`rust/target/`, `gleam/build/`, `elixir/hello_app/_build/`).
