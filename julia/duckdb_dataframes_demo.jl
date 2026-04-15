#!/usr/bin/env julia

using Dates
using DuckDB
using DataFrames
using Statistics

function build_events(days::Int)
    categories = ["books", "games", "coffee", "hardware", "music"]
    start = Date(2026, 1, 1)

    rows = NamedTuple[]
    for d in 0:(days - 1)
        day = start + Day(d)
        for _ in 1:(8 + (d % 5))
            amount = round(5 + rand() * 120; digits=2)
            units = rand(1:4)
            category = categories[rand(1:length(categories))]
            push!(rows, (event_day = day, category = category, amount = amount, units = units))
        end
    end

    DataFrame(rows)
end

events = build_events(20)
con = DBInterface.connect(DuckDB.DB, ":memory:")
DuckDB.register_data_frame(con, events, "events")

summary = DataFrame(
    DBInterface.execute(
        con,
        """
        SELECT
          category,
          ROUND(SUM(amount), 2) AS revenue,
          ROUND(AVG(amount), 2) AS avg_ticket,
          SUM(units) AS units_sold
        FROM events
        GROUP BY category
        ORDER BY revenue DESC
        """,
    ),
)

println("Julia DuckDB + DataFrames Demo")
println("------------------------------")
show(summary, allrows=true, allcols=true)
println("\n")
println("Average category revenue: ", round(mean(summary.revenue); digits=2))

DBInterface.close!(con)
