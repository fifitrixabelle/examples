const C = {
  reset: "\x1b[0m",
  blue: "\x1b[34m",
  cyan: "\x1b[36m",
  yellow: "\x1b[33m",
  bold: "\x1b[1m",
  green: "\x1b[32m",
  magenta: "\x1b[35m",
};

const paint = (color: string, text: string) => `${color}${text}${C.reset}`;
const meter = (count: number) => "▰".repeat(Math.max(1, count));

const source = [
  "00 gate=open band=laser fans=18",
  "01 gate=hold band=glitter fans=24",
  "02 gate=open band=laser fans=27",
  "03 gate=reroute band=echo fans=9",
  "04 gate=open band=bass fans=30",
  "05 gate=open band=glitter fans=21",
];

type Event = { tick: number; gate: string; band: string; fans: number };

const stream = ReadableStream.from(source)
  .pipeThrough(
    new TransformStream<string, Event>({
      transform(chunk, controller) {
        const [tickToken, gateToken, bandToken, fansToken] = chunk.split(" ");
        controller.enqueue({
          tick: Number(tickToken),
          gate: gateToken.split("=")[1]!,
          band: bandToken.split("=")[1]!,
          fans: Number(fansToken.split("=")[1]!),
        });
      },
    }),
  );

const events = await Array.fromAsync(stream);
const byBand = new Map<string, { opens: number; fans: number }>();
for (const event of events) {
  const current = byBand.get(event.band) ?? { opens: 0, fans: 0 };
  byBand.set(event.band, {
    opens: current.opens + (event.gate === "open" ? 1 : 0),
    fans: current.fans + event.fans,
  });
}

console.log(paint(C.blue, "══════════ Deno Stream Control 📻 ══════════"));
console.log(`  ${paint(C.bold, "web streams")} parsing gate events without a bundle in sight`);
console.log();
for (const event of events) {
  const color =
    event.gate === "open" ? C.green : event.gate === "hold" ? C.yellow : C.magenta;
  console.log(
    `  t${paint(C.bold, event.tick.toString().padStart(2, "0"))} ` +
      `${paint(color, event.gate.padEnd(7))} ` +
      `${paint(C.cyan, event.band.padEnd(8))} ` +
      `fans=${paint(C.yellow, event.fans.toString().padStart(2))}`,
  );
}

console.log();
for (const [band, stats] of [...byBand.entries()].sort((a, b) => b[1].fans - a[1].fans)) {
  console.log(
    `  ${paint(C.cyan, band.padEnd(8))} opens=${paint(C.green, stats.opens.toString())} ` +
      `crowd=${paint(C.yellow, stats.fans.toString().padStart(3))} ${paint(C.magenta, meter(Math.round(stats.fans / 10)))}`,
  );
}
