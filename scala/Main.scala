sealed trait Cue
case class Step(delta: Int) extends Cue
case class Warp(target: Int) extends Cue
case class Cool(amount: Int) extends Cue

case class State(position: Int, heat: Int)

object Main {
  private def paint(code: String, text: String): String = s"\u001b[${code}m${text}\u001b[0m"
  private def meter(n: Int): String = "▰" * math.max(1, n)

  private def apply(state: State, cue: Cue): State = cue match {
    case Step(delta) => state.copy(position = state.position + delta, heat = state.heat + math.abs(delta))
    case Warp(target) => state.copy(position = target, heat = state.heat + 4)
    case Cool(amount) => state.copy(heat = math.max(0, state.heat - amount))
  }

  private def render(position: Int): String =
    (-5 to 5).map {
      case 0 => paint("33", "|")
      case idx if idx == position => paint("32", "@")
      case _ => paint("34", ".")
    }.mkString

  def main(args: Array[String]): Unit = {
    val script = List[Cue](Step(1), Step(2), Cool(1), Warp(-2), Step(1), Step(1), Cool(2), Warp(3))
    println(paint("35", "════════ Scala Typed Drift ✨ ════════"))
    println(s"  ${paint("36", "sealed traits")} drive a tiny choreography compiler")
    println()

    val (_, states) = script.foldLeft((State(0, 0), List.empty[(Cue, State)])) {
      case ((state, acc), cue) =>
        val next = apply(state, cue)
        (next, acc :+ (cue -> next))
    }

    states.zipWithIndex.foreach { case ((cue, state), idx) =>
      val label = cue match {
        case Step(delta) => s"step $delta"
        case Warp(target) => s"warp $target"
        case Cool(amount) => s"cool $amount"
      }
      println(
        s"  ${paint("1", s"#${idx + 1}")} ${paint("36", f"$label%-8s")} ${render(state.position)} heat=${paint("35", meter(state.heat / 2 + 1))}"
      )
    }

    println()
    println(s"  final dock: ${paint("32", states.last._2.position.toString)}")
  }
}
