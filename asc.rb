# encoding: utf-8

class Game
  def initialize
    reset
  end
  def reset
    @world = World.new(180)
    @screen = Screen.new(160, 40, @world)
  end
  def run
    loop do
      unless @world.tick
        reset
      end
      render
    end
  end
  def render
    @world.buildings.each do |building|
      @screen.draw(building)
    end
    @screen.draw(@world.player)
    @world.misc.each do |object|
      @screen.draw(object)
    end
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
    renderable.each_pixel(world.ticks) do |x, y, char|
      @fb.set x, y, char
    end
  end
  def render
    print "\e[H"
    buffer = ''
    (0...height).each do |y|
      (OFFSET...(width + OFFSET)).each do |x|
        buffer << @fb.get(x, y)
      end
      buffer << "\n"
    end
    buffer << " ." * (width / 2)
    print buffer
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
    @ticks = 0
    @horizon = horizon
    @building_generator = BuildingGenerator.new(self)
    @player = Player.new(25)
    @buildings = [ Building.new(-10, 30, 100) ]
    @misc = [ Scoreboard.new(self) ]
    @speed = 3
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
      b.x -= speed
    end

    if b = building_under_player
      if player.bottom_y > b.y
        b.x += speed
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
    [35, [previous_building.y - delta, minimum_height_clearance].max].min
  end
end

module Renderable
  def each_pixel ticks
    (y...(y + height)).each do |y|
      (x...(x + width)).each do |x|
        rx = x - self.x
        ry = y - self.y
        yield x, y, char(rx, ry, ticks)
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
  def char rx, ry, ticks
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
    @walking = false
  end
  def x; 0; end
  def width; 1 end
  def height; 3 end
  def char rx, ry, ticks
    if @dead
      %w{ O | \\ }[ry]
    else
      %w{ O | L }[ry]
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
    @velocity = -2.5 if @walking
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
  def char rx, ry, ticks
    "\033[31m$\033[0m"
  end
end

class Scoreboard
  include Renderable
  def initialize world
    @world = world
  end
  def height; 3 end
  def width; 20 end
  def x; -20 end
  def y; 0 end
  def template
    [
      '+------------------+',
      '| Score: %9s |' % [ @world.distance],
      '+------------------+'
    ]
  end
  def char rx, ry, ticks
    template[ry][rx]
  end
end

class GameOverBanner
  include Renderable
  def x; 40 end
  def y; 20 end
  def width; 30 end
  def height; 3 end
  def template
    [
      '-----------------------------',
      '--        Game Over        --',
      '-----------------------------',
    ]
  end
  def char rx, ry, ticks
    template[ry][rx]
  end
end

Game.new.run
