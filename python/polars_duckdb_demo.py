#!/usr/bin/env python3
from __future__ import annotations

from datetime import date, timedelta
from random import Random

import duckdb
import polars as pl


def paint(code: str, text: str) -> str:
    return f"\x1b[{code}m{text}\x1b[0m"


def meter(value: float) -> str:
    return "▰" * max(1, round(value / 2))


def spark(value: float, peak: float) -> str:
    dots = "▁▂▃▄▅▆▇█"
    idx = (
        0 if peak == 0 else min(len(dots) - 1, round((value / peak) * (len(dots) - 1)))
    )
    return dots[idx]


def build_trains(days: int = 18, seed: int = 17) -> pl.DataFrame:
    rng = Random(seed)
    lines = ["violet", "amber", "mint", "laser", "echo"]
    start = date(2026, 2, 1)

    rows: list[dict[str, object]] = []
    for day_offset in range(days):
        current = start + timedelta(days=day_offset)
        for _ in range(rng.randint(7, 12)):
            riders = rng.randint(40, 260)
            delay = round(max(0.0, rng.gauss(6.5, 4.0)), 1)
            rows.append(
                {
                    "service_day": current.isoformat(),
                    "line": rng.choice(lines),
                    "delay_minutes": delay,
                    "riders": riders,
                }
            )
    return pl.DataFrame(rows)


def main() -> None:
    trains = build_trains()

    conn = duckdb.connect(":memory:")
    conn.register("trains", trains)

    hotspots = pl.DataFrame(
        conn.execute(
            """
            SELECT
              line,
              ROUND(AVG(delay_minutes), 2) AS avg_delay,
              ROUND(MAX(delay_minutes), 2) AS peak_delay,
              SUM(riders) AS riders
            FROM trains
            GROUP BY line
            ORDER BY avg_delay DESC, riders DESC
            """
        ).fetchall(),
        schema=["line", "avg_delay", "peak_delay", "riders"],
        orient="row",
    )

    daily = (
        trains.group_by("service_day")
        .agg(
            pl.col("delay_minutes").mean().alias("mean_delay"),
            pl.col("riders").sum().alias("crowd"),
        )
        .sort("service_day")
        .with_columns(
            pl.col("mean_delay")
            .rolling_mean(window_size=4, min_samples=1)
            .alias("rolling_delay")
        )
    )

    peak_delay = max(float(row["mean_delay"]) for row in daily.iter_rows(named=True))
    skyline = "".join(
        spark(float(row["mean_delay"]), peak_delay)
        for row in daily.iter_rows(named=True)
    )

    print(paint("35", "════════ Python Dispatch Lab 🐍 ════════"))
    print(
        f"  {paint('36', 'duckdb + polars')} turn a fake subway week into a delay board"
    )
    print(f"  {paint('33', 'delay skyline')} {paint('35', skyline)}")
    print()
    print(paint("33", "  worst behaved lines:"))
    for index, row in enumerate(hotspots.iter_rows(named=True), start=1):
        avg_delay = float(row["avg_delay"])
        peak = float(row["peak_delay"])
        riders = int(row["riders"])
        print(
            "  "
            f"{paint('1', f'#{index}')} "
            f"{paint('36', str(row['line']).ljust(8))} "
            f"avg={paint('32', f'{avg_delay:>4.1f}m')} "
            f"peak={paint('33', f'{peak:>4.1f}m')} "
            f"riders={paint('34', str(riders).rjust(4))} "
            f"{paint('35', meter(avg_delay))}"
        )

    print()
    print(paint("33", "  rolling control room tape:"))
    for row in daily.tail(8).iter_rows(named=True):
        delay = float(row["mean_delay"])
        rolling = float(row["rolling_delay"])
        crowd = int(row["crowd"])
        print(
            "  "
            f"{paint('36', str(row['service_day']))} "
            f"delay={paint('32', f'{delay:>4.1f}m')} "
            f"avg4={paint('33', f'{rolling:>4.1f}m')} "
            f"crowd={paint('35', str(crowd).rjust(4))}"
        )


if __name__ == "__main__":
    main()
