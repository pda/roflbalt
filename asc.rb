# encoding: utf-8

class Game
  def initialize
    @world = World.new
    @screen = Screen.new(100, 40, @world)
  end
  def run
    loop do
      render
      @world.tick
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
  end
  def create_frame_buffer
    @fb = Framebuffer.new
  end
  def draw renderable
    (renderable.y..(renderable.y + renderable.height)).each do |y|
      (renderable.x..(renderable.x + renderable.width)).each do |x|
        @fb.set x, y, renderable.char
      end
    end
  end
  def render
    print "\e[H"
    (0..height).each do |y|
      (OFFSET..(width - OFFSET)).each do |x|
        print @fb.get(x, y)
      end
      print "\n"
    end
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
    @pixels[x][y] || "."
  end
end

class World
  def initialize
    @player = Player.new(25)
    @buildings = []
    [
      [-10, 30, 20],
      [20, 35, 20],
      [50, 20, 20],
    ].each do |params|
      @buildings << Building.new(*params)
    end
  end
  attr_reader :buildings, :player
  def tick
    buildings.each do |b|
      b.x -= 1
    end
  end
end

class Building < Struct.new(:x, :y, :width)
  def height; 30 end
  def char; "#" end
end

class Player < Struct.new(:y)
  def x; 0; end
  def width; 1 end
  def height; 2 end
  def char; "@" end
end

Game.new.run
