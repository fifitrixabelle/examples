import gleam/int
import gleam/io
import gleam/list
import gleam/string

pub type Move {
  Step(Int)
  Drift(Int)
  Warp(Int)
}

pub type State {
  State(position: Int, heat: Int, trail: List(Int))
}

fn paint(code: String, text: String) -> String {
  "\u{001b}[" <> code <> "m" <> text <> "\u{001b}[0m"
}

fn meter(n: Int) -> String {
  string.repeat("▰", int.max(1, n))
}

fn apply_move(state: State, move: Move) -> State {
  let State(position:, heat:, trail:) = state
  case move {
    Step(delta) -> State(position + delta, heat + int.absolute_value(delta), [position + delta, ..trail])
    Drift(delta) -> State(position + delta, heat + 1, [position + delta, ..trail])
    Warp(dest) -> State(dest, heat + 4, [dest, ..trail])
  }
}

fn render_position(pos: Int) -> String {
  let index = pos + 5
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  |> list.map(fn(i) {
    case i == 5 {
      True -> paint("33", "|")
      False ->
        case i == index {
          True -> paint("32", "@")
          False -> paint("34", ".")
        }
    }
  })
  |> string.concat
}

pub fn main() {
  let moves = [Step(1), Step(1), Drift(-1), Step(2), Warp(-2), Drift(1), Step(2), Step(-1)]
  let initial = State(0, 0, [0])
  let final =
    list.fold(moves, initial, fn(state, move) {
      apply_move(state, move)
    })

  io.println(paint("35", "════════ Gleam Reactor Steps ⚡ ════════"))
  io.println(paint("33", "  typed moves folding into a tiny state machine"))
  io.println("")

  let _ =
    list.fold(moves, #(0, initial), fn(acc, move) {
      let #(index, state) = acc
      let next = apply_move(state, move)
      let State(position:, heat:, trail: _) = next
      io.println(
        "  "
          <> paint("1", "#" <> int.to_string(index + 1))
          <> " "
          <> render_position(position)
          <> "  heat="
          <> paint("35", meter(heat / 2 + 1)),
      )
      #(index + 1, next)
    })

  let State(position:, heat:, trail:) = final
  io.println("")
  io.println("  final dock: " <> paint("36", int.to_string(position)))
  io.println("  heat score: " <> paint("32", int.to_string(heat)))
  io.println("  trail size: " <> paint("33", int.to_string(list.length(trail))))
}
