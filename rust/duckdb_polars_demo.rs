#[derive(Clone, Copy)]
enum Command {
    Boost(u8),
    Cool(u8),
    Warp(i32),
}

#[derive(Clone, Copy)]
struct State {
    lane: i32,
    heat: i32,
    charge: i32,
}

fn paint(code: &str, text: &str) -> String {
    format!("\x1b[{code}m{text}\x1b[0m")
}

fn meter(value: i32) -> String {
    "▰".repeat(((value / 2).max(1)) as usize)
}

fn render_lane(lane: i32) -> String {
    let mut row = String::new();
    for idx in -4..=4 {
        if idx == 0 {
            row.push_str(&paint("33", "|"));
        } else if idx == lane {
            row.push_str(&paint("32", "@"));
        } else {
            row.push_str(&paint("34", "."));
        }
    }
    row
}

fn apply(state: State, command: Command) -> State {
    match command {
        Command::Boost(power) => State {
            lane: state.lane + 1,
            heat: state.heat + i32::from(power),
            charge: state.charge + 2,
        },
        Command::Cool(amount) => State {
            lane: state.lane,
            heat: (state.heat - i32::from(amount)).max(0),
            charge: state.charge + 1,
        },
        Command::Warp(target) => State {
            lane: target,
            heat: state.heat + 4,
            charge: state.charge + 3,
        },
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let script = [
        Command::Boost(3),
        Command::Boost(2),
        Command::Cool(2),
        Command::Warp(-2),
        Command::Boost(4),
        Command::Cool(1),
        Command::Warp(2),
        Command::Boost(1),
    ];

    println!("{}", paint("35", "════════ Rust State Forge 🦀 ════════"));
    println!("{}", paint("33", "  enums and pattern matching drive a tiny reactor cart"));
    println!();

    let mut state = State {
        lane: 0,
        heat: 0,
        charge: 0,
    };
    let mut hottest = state.heat;

    for (idx, command) in script.iter().enumerate() {
        state = apply(state, *command);
        hottest = hottest.max(state.heat);
        let label = match command {
            Command::Boost(power) => format!("boost {}", power),
            Command::Cool(amount) => format!("cool {}", amount),
            Command::Warp(target) => format!("warp {}", target),
        };
        println!(
            "  {} {:<8} {} heat={} charge={}",
            paint("1", &format!("#{}", idx + 1)),
            paint("36", &format!("{label:<8}")),
            render_lane(state.lane),
            paint("35", &meter(state.heat)),
            paint("32", &state.charge.to_string()),
        );
    }

    println!();
    println!("  final lane: {}", paint("36", &state.lane.to_string()));
    println!("  hottest glow: {}", paint("33", &hottest.to_string()));
    Ok(())
}
