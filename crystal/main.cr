record Cue, lane : String, beat : Int32, mood : Int32

def color(code : Int32, text : String)
  "\e[#{code}m#{text}\e[0m"
end

def glyph(mood : Int32)
  return "◆" if mood >= 7
  return "▲" if mood >= 5
  return "■" if mood >= 3
  "·"
end

def meter(values : Array(Int32))
  values.map do |value|
    if value >= 7
      "█"
    elsif value >= 5
      "▆"
    elsif value >= 3
      "▄"
    else
      "·"
    end
  end.join
end

lanes = {
  "ruby"    => {31, 3},
  "prism"   => {36, 5},
  "echo"    => {35, 7},
  "comet"   => {33, 11},
}

channel = Channel(Cue).new
beats = 12

lanes.each do |lane, (_, seed)|
  spawn do
    beats.times do |beat|
      mood = ((seed * (beat + 2)) + beat * 3) % 9
      channel.send(Cue.new(lane, beat, mood))
    end
  end
end

timeline = Hash(Int32, Array(Cue)).new { |hash, key| hash[key] = [] of Cue }
memory = Hash(String, Array(Int32)).new { |hash, key| hash[key] = [] of Int32 }

(lanes.size * beats).times do
  cue = channel.receive
  timeline[cue.beat] << cue
  memory[cue.lane] << cue.mood
end

puts color(35, "════════ Crystal Fiber Parade 💎 ════════")
puts color(33, "  fibers are dropping cues onto a shared channel")
puts

beats.times do |beat|
  row = timeline[beat].sort_by(&.lane).map do |cue|
    lane_color = lanes[cue.lane][0]
    color(lane_color, "#{glyph(cue.mood)} #{cue.lane}")
  end.join("  ")
  crowd = timeline[beat].sum(&.mood)
  puts "  #{color(1, "beat #{beat.to_s.rjust(2, '0')}")}  #{row}  crowd=#{color(32, "▰" * (crowd // 6).clamp(1, 8))}"
end

puts
memory.keys.sort.each do |lane|
  lane_color = lanes[lane][0]
  puts "  #{color(lane_color, lane.ljust(8))} #{color(lane_color, meter(memory[lane]))}"
end
