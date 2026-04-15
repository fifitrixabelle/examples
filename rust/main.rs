const RESET: &str = "\x1b[0m";
const BOLD: &str = "\x1b[1m";
const MAGENTA: &str = "\x1b[35m";
const CYAN: &str = "\x1b[36m";
const GREEN: &str = "\x1b[32m";
const YELLOW: &str = "\x1b[33m";
const BLUE: &str = "\x1b[34m";

struct Signal<'a> {
    name: &'a str,
    phase: i32,
    amplitude: i32,
}

fn paint(color: &str, text: impl AsRef<str>) -> String {
    format!("{color}{}{RESET}", text.as_ref())
}

fn meter(width: i32, offset: i32, color: &str) -> String {
    let clamped = offset.clamp(-width, width);
    let mut line = String::new();

    for pos in -width..=width {
        if pos == 0 {
            line.push_str(&paint(BLUE, "│"));
        } else if pos == clamped {
            line.push_str(&paint(color, "●"));
        } else {
            line.push_str("·");
        }
    }

    line
}

fn main() {
    let signals = [
        Signal {
            name: "aurora",
            phase: 5,
            amplitude: 9,
        },
        Signal {
            name: "meteor",
            phase: -7,
            amplitude: 12,
        },
        Signal {
            name: "quasar",
            phase: 3,
            amplitude: 15,
        },
        Signal {
            name: "comet",
            phase: -2,
            amplitude: 8,
        },
    ];

    println!(
        "{}{}Rust Signal Arcade 🦀{}",
        MAGENTA, BOLD, RESET
    );
    println!(
        "  {}Each channel gets a drift score and a tiny neon scope.{}",
        CYAN, RESET
    );

    for (idx, signal) in signals.iter().enumerate() {
        let drift = signal.phase * signal.amplitude;
        let hue = match idx % 4 {
            0 => CYAN,
            1 => YELLOW,
            2 => GREEN,
            _ => MAGENTA,
        };

        println!(
            "  {}  phase={}  amp={}  drift={}  {}",
            paint(hue, format!("{:<7}", signal.name)),
            paint(CYAN, format!("{:>3}", signal.phase)),
            paint(YELLOW, format!("{:>3}", signal.amplitude)),
            paint(GREEN, format!("{:>4}", drift)),
            meter(16, signal.phase, hue),
        );
    }

    let total_energy: i32 = signals.iter().map(|signal| signal.amplitude.abs()).sum();
    let brightest = signals
        .iter()
        .max_by_key(|signal| signal.amplitude)
        .map(|signal| signal.name)
        .unwrap_or("none");

    println!();
    println!(
        "  total energy: {}",
        paint(GREEN, total_energy.to_string())
    );
    println!(
        "  brightest arc: {}",
        paint(MAGENTA, brightest)
    );
}
