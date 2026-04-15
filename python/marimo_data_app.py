"""Launch with: uv run marimo run marimo_data_app.py"""

import marimo

__generated_with = "0.13.0"
app = marimo.App(width="medium")


@app.cell
def _():
    from datetime import date, timedelta
    from random import Random

    import duckdb
    import marimo as mo
    import polars as pl

    return Random, date, duckdb, mo, pl, timedelta


@app.cell
def _(Random, date, timedelta, pl):
    rng = Random(12)
    categories = ["books", "games", "coffee", "hardware", "music"]
    start = date(2026, 1, 1)

    _rows = []
    for day_offset in range(30):
        day = start + timedelta(days=day_offset)
        for _ in range(rng.randint(6, 13)):
            _rows.append(
                {
                    "event_day": day.isoformat(),
                    "category": rng.choice(categories),
                    "amount": round(rng.uniform(5.0, 150.0), 2),
                }
            )

    events = pl.DataFrame(_rows)
    return (events,)


@app.cell
def _(mo):
    chosen = mo.ui.dropdown(
        options=["all", "books", "games", "coffee", "hardware", "music"],
        value="all",
        label="Category",
    )
    return (chosen,)


@app.cell
def _(mo):
    limit = mo.ui.slider(start=3, stop=20, step=1, value=8, label="Top rows")
    return (limit,)


@app.cell
def _(events, chosen, limit, duckdb, pl):
    con = duckdb.connect(":memory:")
    con.register("events", events)

    where_clause = "" if chosen.value == "all" else f"WHERE category = '{chosen.value}'"
    rows = con.execute(
        f"""
        SELECT event_day, category, ROUND(SUM(amount), 2) AS revenue
        FROM events
        {where_clause}
        GROUP BY event_day, category
        ORDER BY revenue DESC
        LIMIT {limit.value}
        """
    ).fetchall()

    table = pl.DataFrame(
        rows, schema=["event_day", "category", "revenue"], orient="row"
    )
    return (table,)


@app.cell
def _(mo, chosen, limit, table):
    mo.vstack(
        [
            mo.md("# marimo + DuckDB + Polars\nInteractive local analytics demo."),
            mo.hstack([chosen, limit], justify="start"),
            table,
        ]
    )
    return


if __name__ == "__main__":
    app.run()
