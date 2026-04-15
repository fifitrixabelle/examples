local C = {
  reset = "\27[0m",
  magenta = "\27[35m",
  cyan = "\27[36m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
}

local function paint(color, text)
  return color .. text .. C.reset
end

local actors = {
  { name = "hero", color = C.green, pos = 0, script = { 1, 1, -1, 2, 0, -1 } },
  { name = "ghost", color = C.cyan, pos = 2, script = { 0, -1, -1, 1, 1, 0 } },
  { name = "orb", color = C.yellow, pos = -2, script = { 1, 0, 1, 0, -1, 1 } },
}

local function render_scene(list)
  local out = {}
  for x = -4, 4 do
    local glyph = paint(C.blue, ".")
    if x == 0 then
      glyph = paint(C.magenta, "|")
    end
    for _, actor in ipairs(list) do
      if actor.pos == x then
        glyph = paint(actor.color, string.sub(actor.name, 1, 1))
      end
    end
    table.insert(out, glyph)
  end
  return table.concat(out)
end

print(paint(C.magenta, "════════ Lua Pocket Stage 🎢 ════════"))
print("  " .. paint(C.cyan, "tiny game-loop energy") .. " with scripted actors")
print()

for tick = 1, 6 do
  for _, actor in ipairs(actors) do
    actor.pos = actor.pos + actor.script[tick]
  end
  print("  " .. paint(C.yellow, "tick " .. tick) .. "  " .. render_scene(actors))
end

print()
for _, actor in ipairs(actors) do
  print("  " .. paint(actor.color, actor.name) .. " final x=" .. paint(C.green, tostring(actor.pos)))
end
