# frozen_string_literal: true

RESET = "\e[0m"
COLORS = {
  magenta: "\e[35m",
  cyan: "\e[36m",
  green: "\e[32m",
  yellow: "\e[33m",
  blue: "\e[34m",
  white: "\e[97m"
}.freeze

def paint(color, text)
  "#{COLORS.fetch(color)}#{text}#{RESET}"
end

class ClubScript
  Cue = Struct.new(:lane, :action, :energy, :color, keyword_init: true)

  attr_reader :cues

  def initialize
    @cues = []
  end

  def lane(name, color, &block)
    LaneBuilder.new(name, color, @cues).instance_eval(&block)
  end

  class LaneBuilder
    def initialize(name, color, cues)
      @name = name
      @color = color
      @cues = cues
    end

    def hit(action, energy)
      @cues << Cue.new(lane: @name, action: action, energy: energy, color: @color)
    end
  end
end

script = ClubScript.new
script.instance_eval do
  lane('laser', :cyan) do
    hit 'open mirrors', 8
    hit 'slice haze', 6
  end

  lane('glitter', :yellow) do
    hit 'drop shimmer', 5
    hit 'tilt disco ball', 7
  end

  lane('midnight', :blue) do
    hit 'flood bass bins', 9
    hit 'fade to cobalt', 4
  end
end

puts paint(:magenta, '════════ Ruby Club DSL 🎛️ ════════')
puts "  #{paint(:cyan, 'instance_eval')} scripts a tiny stage show with a friendly DSL"
puts

script.cues.each_with_index do |cue, index|
  energy = paint(cue.color, '▰' * [(cue.energy / 2.0).round.clamp(1, 8), 1].max)
  puts "  #{paint(:white, "##{index + 1}")} #{paint(cue.color, cue.lane.ljust(9))} #{cue.action.ljust(18)} #{energy}"
end

puts
headline = script.cues.max_by(&:energy)
puts "  loudest lane: #{paint(headline.color, headline.lane)}"
puts "  total cues: #{paint(:green, script.cues.length.to_s)}"
