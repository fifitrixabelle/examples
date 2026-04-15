const C = {
  reset: "\x1b[0m",
  cyan: "\x1b[36m",
  magenta: "\x1b[35m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  bold: "\x1b[1m",
  blue: "\x1b[34m",
};

const paint = (color: string, text: string) => `${color}${text}${C.reset}`;
const line = (label: string) =>
  paint(C.magenta, "━".repeat(12)) + ` ${paint(C.bold, label)} ` + paint(C.magenta, "━".repeat(12));
const meter = (value: number) => "▰".repeat(Math.max(1, Math.round(value / 2)));

type Cue = {
  lane: string;
  delay: number;
  energy: number;
  action: string;
  color: string;
};

const cues: Cue[] = [
  { lane: "laser", delay: 45, energy: 7, action: "ignite mirrors", color: C.cyan },
  { lane: "glitter", delay: 20, energy: 5, action: "drop confetti", color: C.yellow },
  { lane: "bass", delay: 70, energy: 8, action: "shake subfloor", color: C.green },
  { lane: "smoke", delay: 35, energy: 4, action: "roll fog wall", color: C.blue },
  { lane: "strobe", delay: 55, energy: 6, action: "flash checker", color: C.magenta },
];

async function runCue(cue: Cue) {
  const start = Bun.nanoseconds();
  await Bun.sleep(cue.delay);
  const end = Bun.nanoseconds();
  return {
    ...cue,
    elapsedMs: Number(end - start) / 1_000_000,
  };
}

console.log(line("Bun Backstage Queue"));
console.log(`  ${paint(C.cyan, "Bun.sleep")} launches a tiny stage crew in parallel`);
console.log();

const settled = await Promise.all(cues.map(runCue));
const completion = settled.toSorted((a, b) => a.elapsedMs - b.elapsedMs);
for (const [index, cue] of completion.entries()) {
  console.log(
    `  ${paint(C.bold, `#${index + 1}`)} ${paint(cue.color, cue.lane.padEnd(8))} ` +
      `${paint(C.yellow, `${cue.elapsedMs.toFixed(1).padStart(5)}ms`)} ` +
      `${cue.action} ${paint(cue.color, meter(cue.energy))}`,
  );
}

console.log();
const totalEnergy = completion.reduce((sum, cue) => sum + cue.energy, 0);
const fastest = completion[0]!;
const slowest = completion.at(-1)!;
console.log(`  first out: ${paint(fastest.color, fastest.lane)} with ${paint(C.cyan, fastest.action)}`);
console.log(`  final cue: ${paint(slowest.color, slowest.lane)} after ${paint(C.yellow, `${slowest.elapsedMs.toFixed(1)}ms`)}`);
console.log(`  room charge: ${paint(C.green, totalEnergy.toString())} bars ${paint(C.magenta, meter(totalEnergy / 2))}`);
