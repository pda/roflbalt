# encoding: utf-8

class Game
  def initialize
    @world = World.new
    @screen = Screen.new(100, 40, @world)
  end
  def render
    @world.buildings.each do |building|
      @screen.draw(building)
    end
    #@screen.draw(@world.player)
    @screen.render
  end
end

class Screen < Struct.new(:width, :height, :world)
  OFFSET = -20
  def initialize width, height, world
    super
    @fb = Framebuffer.new
  end
  def draw renderable
    p "DRAWING"
    (0..renderable.y).each do |i|
      y = renderable.y - i
      (renderable.x..(renderable.x + renderable.width)).each do |x|
        @fb.set x, y, renderable.char
      end
    end
  end
  def render
    (0..height).each do |i|
      y = height - i
      (OFFSET..(width - OFFSET)).each do |x|
        print @fb.get(x, y)
      end
      print "\n"
    end
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
    @player = Player.new(12)
    @buildings = []
    @buildings << Building.new(20, 10, -10)
    @buildings << Building.new(12, 13, 20)
  end
  attr_reader :buildings, :player
end

class Building < Struct.new(:width, :height, :x)
  alias_method :y, :height
  def char; "#" end
end

class Player < Struct.new(:y)
  def x; 0; end
  def width; 1 end
  def height; 2 end
  def char; "@" end
end

Game.new.render
