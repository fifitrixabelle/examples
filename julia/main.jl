#!/usr/bin/env julia

function paint(code, text)
    return "\e[" * code * "m" * text * "\e[0m"
end

function lorenz(steps)
    x, y, z = 0.1, 0.0, 0.0
    σ, ρ, β = 10.0, 28.0, 8 / 3
    points = Tuple{Float64, Float64}[]
    dt = 0.01
    for _ in 1:steps
        dx = σ * (y - x)
        dy = x * (ρ - z) - y
        dz = x * y - β * z
        x += dx * dt
        y += dy * dt
        z += dz * dt
        push!(points, (x, z))
    end
    points
end

function render(points, width, height)
    xs = first.(points)
    ys = last.(points)
    xmin, xmax = minimum(xs), maximum(xs)
    ymin, ymax = minimum(ys), maximum(ys)
    grid = [fill(' ', width) for _ in 1:height]

    for (x, y) in points
        xi = clamp(round(Int, (x - xmin) / (xmax - xmin + eps()) * (width - 1)) + 1, 1, width)
        yi = clamp(round(Int, (y - ymin) / (ymax - ymin + eps()) * (height - 1)) + 1, 1, height)
        grid[height - yi + 1][xi] = '*'
    end
    join(String.(grid), "\n")
end

points = lorenz(1800)
art = render(points[600:end], 44, 18)

println(paint("35", "════════ Julia Strange Attractor 🌌 ════════"))
println("  " * paint("36", "Lorenz drift") * " projected into a tiny terminal sky")
println()
for (idx, line) in enumerate(split(art, "\n"))
    color = isodd(idx) ? "35" : "36"
    println("  " * paint(color, line))
end
println()
println("  samples: " * paint("33", string(length(points))) * " points")
