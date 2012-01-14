# encoding: utf-8

class Game
  def initialize
    @world = World.new(180)
    @screen = Screen.new(160, 50, @world)
  end
  def run
    loop do
      @world.tick
      render
    end
  end
  def render
    @world.buildings.each do |building|
      @screen.draw(building)
    end
    @screen.draw(@world.player)
    @screen.render
  end
end

class Screen < Struct.new(:width, :height, :world)
  OFFSET = -20
  def initialize width, height, world
    super
    create_frame_buffer
    %x{stty -icanon -echo}
    print "\033[2J" # clear screen
    print "\x1B[?25l" # disable cursor
  end
  def create_frame_buffer
    @fb = Framebuffer.new
  end
  def draw renderable
    renderable.each_pixel do |x, y, char|
      @fb.set x, y, char
    end
  end
  def render
    print "\e[H"
    (0...height).each do |y|
      (OFFSET...(width + OFFSET)).each do |x|
        print @fb.get(x, y)
      end
      print "\n"
    end
    print " b:#{world.buildings.size}"
    print " ob?:#{world.building_under_player ? "yes" : "no"}"
    puts " |" * (width / 2)
    create_frame_buffer
  end
end

class Framebuffer
  def initialize
    @pixels = Hash.new { |h, k| h[k] = {} }
  end
  def set x, y, char
    @pixels[x][y] = char
  end
  def get x, y
    @pixels[x][y] || " "
  end
end

class World
  def initialize horizon
    @horizon = horizon
    @building_generator = BuildingGenerator.new(self)
    @player = Player.new(25)
    @buildings = [ Building.new(-10, 40, 100) ]
    @speed = 4
  end
  attr_reader :buildings, :player, :horizon, :speed
  def tick
    # TODO: this, but less often.
    @building_generator.generate_if_necessary
    @building_generator.destroy_if_necessary

    buildings.each do |b|
      b.x -= speed
    end

    if b = building_under_player
      if player.bottom_y > b.y
        b.x += speed
        @speed = 0
      end
    end

    begin
      player.jump if STDIN.read_nonblock(1)
    rescue Errno::EAGAIN
    end

    player.tick

    if b = building_under_player
      player.walk_on_building b if player.bottom_y >= b.y
    end

  end
  def building_under_player
    buildings.detect do |b|
      b.x <= player.x && b.right_x >= player.right_x
    end
  end
end

class BuildingGenerator < Struct.new(:world)
  def destroy_if_necessary
    while world.buildings.any? && world.buildings.first.x < -200
      world.buildings.shift
    end
  end
  def generate_if_necessary
    while (b = world.buildings.last).x < world.horizon
      world.buildings << Building.new(
        b.right_x + minimium_gap + rand(24),
        next_y(b),
        rand(30) + 30
      )
    end
  end
  def minimium_gap; 8 end
  def maximum_height_delta; 10 end
  def minimum_height_clearance; 20; end
  def next_y previous_building
    p = previous_building
    delta = maximum_height_delta * -1 + rand(2 * maximum_height_delta + 1)
    [40, [previous_building.y - delta, minimum_height_clearance].max].min
  end
end

module Renderable
  def each_pixel
    (y...(y + height)).each do |y|
      (x...(x + width)).each do |x|
        rx = x - self.x
        ry = y - self.y
        yield x, y, char(rx, ry)
      end
    end
  end
  def right_x; x + width end
end

class Building < Struct.new(:x, :y, :width)
  include Renderable
  def initialize x, y, width
    super
    @period = rand(4) + 6
    @window_width = @period - rand(2) - 1
  end
  def height; 50 end
  def char rx, ry
    if ry == 0
      "="
    elsif [ 0, width - 1 ].include? rx
      "|"
    else
      rx % @period >= @period - @window_width && ry % 5 >= 2 ? " " : "#"
    end
  end
end

class Player
  include Renderable
  def initialize y
    @y = y
    @velocity = 1
  end
  def x; 0; end
  def width; 1 end
  def height; 3 end
  def char rx, ry
    %w{ @ | L }[ry]
  end
  def acceleration; 16.0 end
  def tick
    @y += @velocity
    @velocity += acceleration * 0.01
  end
  def y; @y.round end
  def bottom_y; y + height end
  def walk_on_building b
    @y = b.y - height
    @velocity = 0
  end
  def jump
    @velocity = -2
  end
end

Game.new.run
