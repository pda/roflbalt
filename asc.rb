# encoding: utf-8

class Game
  def initialize
    reset
  end
  def reset
    @run = true
    background = Background.new
    @world = World.new(120, background)
    @screen = Screen.new(120, 40, @world, background)
  end
  def run
    Signal.trap(:INT) do
      @run = false
    end
    while @run
      start_time = Time.new.to_f
      unless @world.tick
        reset
      end
      render start_time
    end
    on_exit
  end
  def render start_time
    @world.buildings.each do |building|
      @screen.draw(building)
    end
    @screen.draw(@world.player)
    @world.misc.each do |object|
      @screen.draw(object)
    end
    @screen.render start_time
  end
  def on_exit
    @screen.on_exit
  end
end

class Screen
  OFFSET = -20
  def initialize width, height, world, background
    @width = width
    @height = height
    @world = world
    @background = background
    create_frame_buffer
    %x{stty -icanon -echo}
    print "\033[0m" # reset
    print "\033[2J" # clear screen
    print "\x1B[?25l" # disable cursor
  end
  attr_reader :width, :height, :world
  def create_frame_buffer
    @fb = Framebuffer.new @background
  end
  def draw renderable
    renderable.each_pixel(world.ticks) do |x, y, pixel|
      @fb.set x, y, pixel
    end
  end
  def render start_time
    print "\e[H"
    buffer = ''
    previous_pixel = nil
    (0...height).each do |y|
      (OFFSET...(width + OFFSET)).each do |x|
        pixel = @fb.get(x, y)
        if Pixel === previous_pixel && Pixel === pixel && pixel.color_equal?(previous_pixel)
          buffer << pixel.char
        else
          buffer << pixel.to_s
        end
        previous_pixel = pixel
      end
      buffer << "\n"
    end
    print "\033[0m"

    dt = Time.new.to_f - start_time;
    target_time = 0.04
    sleep target_time - dt if dt < target_time

    print buffer
    create_frame_buffer
  end
  def on_exit
    print "\033[0m" # reset colours
    print "\x1B[?25h" # re-enable cursor
    print "\n"
  end
end

class Pixel
  def initialize char = " ", fg = nil, bg = nil
    @char = char
    @fg, @bg = fg, bg
  end
  attr_reader :char
  def fg; @fg || 255 end
  def bg; @bg || 0 end
  def to_s
    "\033[48;5;%dm\033[38;5;%dm%s" % [ bg, fg, @char ]
  end
  def color_equal? other
    fg == other.fg && bg == other.bg
  end
end

class Background
  PALETTE = [ 16, 232, 233 ]
  PERIOD = 5.0
  SPEED = 10.0
  def pixel x, y, char = " "
    Pixel.new char, 0, color(x, y)
  end
  def color x, y
    sin = Math.sin((x + Time.new.to_f * SPEED) / PERIOD + y / PERIOD)
    PALETTE[(0.9 * sin + 0.9).round]
  end
end

class WindowColor
  PALETTE = [ 16, 60 ]
  PERIOD = 6.0
  def pixel x, y, char = " "
    Pixel.new char, 0, color(x, y)
  end
  def color x, y
    sin = Math.sin(x / PERIOD + y / (PERIOD * 0.5))
    PALETTE[(0.256 * sin + 0.256).round]
  end
end

class Framebuffer
  def initialize background
    @pixels = Hash.new { |h, k| h[k] = {} }
    @background = background
  end
  def set x, y, pixel
    @pixels[x][y] = pixel
  end
  def get x, y
    @pixels[x][y] || @background.pixel(x, y)
  end
  def size
    @pixels.values.reduce(0) { |a, v| a + v.size }
  end
end

class World
  def initialize horizon, background
    @ticks = 0
    @horizon = horizon
    @building_generator = BuildingGenerator.new(self, WindowColor.new)
    @player = Player.new(25, background)
    @buildings = [ @building_generator.build(-10, 30, 120) ]
    @misc = [ Scoreboard.new(self), RoflCopter.new(50, 4, background) ]
    @speed = 4
    @distance = 0
  end
  attr_reader :buildings, :player, :horizon, :speed, :misc, :ticks, :distance
  def tick
    # TODO: this, but less often.
    if @ticks % 20 == 0
      @building_generator.generate_if_necessary
      @building_generator.destroy_if_necessary
    end

    @distance += speed

    buildings.each do |b|
      b.move_left speed
    end

    if b = building_under_player
      if player.bottom_y > b.y
        b.move_left(-speed)
        @speed = 0
        @misc << Blood.new(player.x, player.y)
        @misc << GameOverBanner.new
        player.die!
      end
    end

    begin
      if STDIN.read_nonblock(1)
        if player.dead?
          return false
        else
          player.jump
        end
      end
    rescue Errno::EAGAIN
    end

    player.tick

    if b = building_under_player
      player.walk_on_building b if player.bottom_y >= b.y
    end

    @ticks += 1
  end
  def building_under_player
    buildings.detect do |b|
      b.x <= player.x && b.right_x >= player.right_x
    end
  end
end

class BuildingGenerator
  def initialize world, background
    @world = world
    @background = background
  end
  def destroy_if_necessary
    while @world.buildings.any? && @world.buildings.first.x < -100
      @world.buildings.shift
    end
  end
  def generate_if_necessary
    while (b = @world.buildings.last).x < @world.horizon
      @world.buildings << build(
        b.right_x + minimium_gap + rand(24),
        next_y(b),
        rand(40) + 40
      )
    end
  end
  def minimium_gap; 16 end
  def maximum_height_delta; 10 end
  def minimum_height_clearance; 20; end
  def next_y previous_building
    p = previous_building
    delta = maximum_height_delta * -1 + rand(2 * maximum_height_delta + 1)
    [25, [previous_building.y - delta, minimum_height_clearance].max].min
  end
  def build x, y, width
    Building.new x, y, width, @background
  end
end

module Renderable
  def each_pixel ticks
    (y...(y + height)).each do |y|
      (x...(x + width)).each do |x|
        rx = x - self.x
        ry = y - self.y
        yield x, y, pixel(x, y, rx, ry, ticks)
      end
    end
  end
  def right_x; x + width end
end

class Building
  include Renderable
  def initialize x, y, width, background
    @x, @y = x, y
    @width = width
    @background = background
    @period = rand(4) + 6
    @window_width = @period - rand(2) - 1
    @color = (235..238).to_a.sample
    @top_color = @color + 4
    @left_color = @color + 2
  end
  attr_reader :x, :y, :width
  def move_left distance
    @x -= distance
  end
  def height; 20 end
  def pixel x, y, rx, ry, ticks
    if ry == 0
      if rx == width - 1
        Pixel.new " "
      else
        Pixel.new "=", 234, @top_color
      end
    elsif rx == 0 || rx == 1
      Pixel.new ":", @left_color + 1, @left_color
    elsif rx == 2
      Pixel.new ":", 236, 236
    elsif rx == width - 1
      Pixel.new ":", 236, 236
    else
      if rx % @period >= @period - @window_width && ry % 5 >= 2
        Pixel.new(" ", 255, @background.color(rx + x/2, ry))
      else
        Pixel.new(":", 235, @color)
      end
    end
  end
end

class Player
  include Renderable
  def initialize y, background
    @y = y
    @background = background
    @velocity = 1
    @walking = false
  end
  def x; 0; end
  def width; 3 end
  def height; 3 end
  def pixel x, y, rx, ry, ticks
    Pixel.new char(rx, ry, ticks), 255, @background.color(x, y)
  end

  def char rx, ry, ticks
    if dead?
      [
        ' @ ',
        '\+/',
        ' \\\\',
      ][ry][rx]
    elsif !@walking
      [
        ' O/',
        '/| ',
        '/ >',
      ][ry][rx]
    else
      [
        [
          ' O ',
          '/|v',
          '/ >',
        ],
        [
          ' 0 ',
          ',|\\',
          ' >\\',
        ],
      ][ticks / 4 % 2][ry][rx]
    end
  end
  def acceleration
    if @dead
      0
    else
      0.35
    end
  end
  def tick
    @y += @velocity
    @velocity += acceleration
    @walking = false
  end
  def y; @y.round end
  def bottom_y; y + height end
  def walk_on_building b
    @y = b.y - height
    @velocity = 0
    @walking = true
  end
  def jump
    jump! if @walking
  end
  def jump!
    @velocity = -2.5
  end
  def die!
    @dead = true
    @velocity = 0.5
  end
  def dead?
    @dead
  end
end

class Blood < Struct.new(:x, :y)
  include Renderable
  def height; 4 end
  def width; 2 end
  def x; super + 2 end
  def pixel x, y, rx, ry, ticks
    "\033[48;5;52m\033[38;5;124m:\033[0m"
  end
end

class Scoreboard
  include Renderable
  def initialize world
    @world = world
  end
  def height; 3 end
  def width; 20 end
  def x; -18 end
  def y; 1 end
  def template
    [
      '                    ',
      '  Score: %9s  ' % [ @world.distance],
      '                    '
    ]
  end
  def pixel x, y, rx, ry, ticks
    Pixel.new template[ry][rx], 244, 234
  end
end

class GameOverBanner
  FG = 16
  BG = 244
  include Renderable
  def x; 28 end
  def y; 14 end
  def width; 28 end
  def height; 3 end
  def template
    [
      '                            ',
      '       YOU DIED. LOL.       ',
      '                            ',
    ]
  end
  def pixel x, y, rx, ry, ticks
    Pixel.new template[ry][rx], FG, BG
  end
end

class RoflCopter
  include Renderable
  def initialize x, y, background
    @x, @y = x, y
    @background = background
    @frames = [
      [
        '          :LoL:ROFL:ROFL',
        '  L     ____|__         ',
        '  O ===`      []\       ',
        '  L     \________]      ',
        '       .__|____|__/     ',
      ],
      [
        ' ROFL:ROFL:LoL:         ',
        '        ____|__         ',
        ' LOL===`      []\       ',
        '        \________]      ',
        '       .__|____|__/     ',
      ],
    ]
  end
  def width; 24 end
  def height; 5 end
  def y
    range = 1.5
    @y + (range * Math.sin(Time.new.to_f * 1.5)).round
  end
  def x
    range = 20
    @x + (range * Math.sin(Time.new.to_f * 0.7)).round
  end
  def pixel x, y, rx, ry, ticks
    Pixel.new char(rx, ry, ticks), 246, @background.color(x, y)
  end
  def char rx, ry, ticks
    @frames[ticks % 2][ry][rx] || " "
  rescue
    " " # Roflcopter crashes from time to time..
  end
end
