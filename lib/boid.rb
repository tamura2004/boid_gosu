require "bundler"
Bundler.require
# require "gosu"
# require "pry"

WIDTH = 600
HEIGHT = 600
SEPARATE_RADIUS = 20
SEPARATE_SPD = 1
SEPARATE_RATE = 0.05
COHERE_SPD = 1
COHERE_RATE = 0.01
ALIGN_RATE = 0.05
ALIGN_RADIUS = 50
ESCAPE_RADIUS = 200
ESCAPE_SPD = 5
ESCAPE_RATE = 0.3
CHASE_RADIUS = 200
CHASE_SPD = 3
CHASE_RATE = 0.01

# 平均
class Object;def try(*options);self&&send(*options);end;end
class Array;def avg;reduce(:+).try(:/,size);end;end


# 個体クラス
class Boid
  attr_accessor :pos,:vel

  def initialize(img,t=90,r=5,x=(WIDTH/2),y=(HEIGHT/2))
    @img = img
    @pos = Complex.rect(x,y)
    @vel = Complex.polar(r,t*Math::PI/180)
  end

  def update
    @pos += @vel
    @pos = Complex.rect(@pos.real%WIDTH,@pos.imag%HEIGHT)
  end

  def draw
    @img.draw_rot(*@pos.rect,0,@vel.arg*180/Math::PI)
  end

  def change(r,t,p)
    @vel *= (Complex.polar(r,t)/@vel)**p
  end
end


# 群れクラス
class Boids < Array

  # 更新
  def update
    separate()
    cohere()
    align()
    each(&:update)
  end

  def draw; each(&:draw); end

  # 分離
  def separate
    combination(2) do |b1,b2|
      rel = b1.pos - b2.pos
      if rel.abs < SEPARATE_RADIUS
        b1.change(SEPARATE_SPD,rel.arg,SEPARATE_RATE)
        b2.change(SEPARATE_SPD,(-rel).arg,SEPARATE_RATE)
      end
    end
  end

  # 集合
  def cohere
    return if empty?
    center = map(&:pos).avg
    each do |b|
      arg = (center - b.pos).arg
      b.change(COHERE_SPD,arg,COHERE_RATE)
    end
  end

  # 整列
  def align
    each do |boid|
      g = group(boid,ALIGN_RADIUS)
      next if g.empty?
      group_vel = g.map(&:vel).avg
      boid.change(*group_vel.polar,ALIGN_RATE)
    end
  end

  # 範囲内の群れ
  def group(boid,r)
    select{|b|(b.pos-boid.pos).abs < r}.tap do |g|
      yield g if block_given? && !g.empty?
    end
  end
end

# 捕食者
class Enemy < Boid
  def update(boids)

    # 追う
    boids.group(self,CHASE_RADIUS) do |targets|
      center = targets.map(&:pos).avg
      change(CHASE_SPD,(center - @pos).arg,CHASE_RATE)
    end
    super()

    # 食べる
    boids.reject! do |b|
      (b.pos - @pos).abs < 16
    end

    # 逃げる
    boids.group(self,ESCAPE_RADIUS) do |targets|
      targets.each do |boid|
        rel = (boid.pos - @pos)
        arg = rel.arg
        if (boid.vel/rel).imag > 0
          arg += Math::PI/2
        else
          arg -= Math::PI/2
        end
        boid.change(ESCAPE_SPD,arg,ESCAPE_RATE)
      end
    end
  end
end

# ウィンドウ
class Scene < Gosu::Window
  def initialize
    super WIDTH,HEIGHT,false
    shark_path = File.join(File.expand_path(File.dirname(__FILE__)),"shark.png")
    delta_path = File.join(File.expand_path(File.dirname(__FILE__)),"delta.png")

    @enemy1 = Enemy.new(Gosu::Image.new(self,shark_path,false),rand(360),5,rand(WIDTH),rand(HEIGHT))
    @boids = Boids.new
    @img = Gosu::Image.new(self,delta_path,false)
    150.times{@boids << Boid.new(@img,rand(360),5,rand(WIDTH),rand(HEIGHT))}
    @font = Gosu::Font.new(self,Gosu::default_font_name,20)
  end

  def update
    @boids.update
    @enemy1.update(@boids)
  end

  def draw
    @boids.draw
    @enemy1.draw
    @font.draw("number of boid: #{@boids.size}",10,10,ZOrder::UI,1.0,1.0,0xffffff00)
  end
end

module ZOrder
  Background,Stars,Player,UI = *0..3
end

scene = Scene.new
scene.show