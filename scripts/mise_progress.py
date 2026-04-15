#!/usr/bin/env python3

from __future__ import annotations

import argparse
import os
import shlex
import subprocess
import sys
import time

RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"
CYAN = "\033[36m"
GREEN = "\033[32m"
MAGENTA = "\033[35m"
YELLOW = "\033[33m"
RED = "\033[31m"

BAR_WIDTH = 30


def style(text: str, *codes: str) -> str:
    return f"{''.join(codes)}{text}{RESET}"


def fmt_duration(seconds: float) -> str:
    if seconds < 1:
        return f"{seconds * 1000:.0f}ms"
    return f"{seconds:.1f}s"


def progress_bar(index: int, total: int) -> str:
    filled = 0 if total == 0 else int(index * BAR_WIDTH / total)
    percent = 0 if total == 0 else int(index * 100 / total)
    bar = "#" * filled + "-" * (BAR_WIDTH - filled)
    return f"[{bar}] {percent:3d}%"


def run_task(task: str, index: int, total: int) -> None:
    print(style(progress_bar(index, total), BOLD, CYAN), f" {index:02d}/{total:02d}")
    print(style(f"-> {task}", BOLD, MAGENTA))
    print(style("-" * 60, DIM))
    sys.stdout.flush()

    started = time.perf_counter()
    try:
        subprocess.run(["mise", "run", task], check=True)
    except subprocess.CalledProcessError as exc:
        elapsed = fmt_duration(time.perf_counter() - started)
        print(style(f"task failed after {elapsed}: {task}", BOLD, RED), file=sys.stderr)
        raise SystemExit(exc.returncode) from exc

    elapsed = fmt_duration(time.perf_counter() - started)
    print(style(f"done in {elapsed}", GREEN))
    print()


def main() -> int:
    parser = argparse.ArgumentParser(description="Pretty progress runner for mise tasks.")
    parser.add_argument("--label", required=True, help="Section label to show.")
    parser.add_argument("tasks", nargs="+", help="mise task names to run in order.")
    args = parser.parse_args()

    started = time.perf_counter()
    total = len(args.tasks)
    command_preview = " ".join(shlex.quote(task) for task in args.tasks)

    print(style("=" * 60, DIM))
    print(style(args.label, BOLD))
    print(style("=" * 60, DIM))
    print(style(f"cwd: {os.getcwd()}", DIM))
    print(style(f"tasks: {command_preview}", DIM))
    print()

    for index, task in enumerate(args.tasks, start=1):
        run_task(task, index, total)

    elapsed = fmt_duration(time.perf_counter() - started)
    print(style("=" * 60, DIM))
    print(style(f"completed {total} tasks in {elapsed}", BOLD, GREEN))
    print(style("=" * 60, DIM))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
