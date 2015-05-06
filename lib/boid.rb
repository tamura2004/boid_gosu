require "gosu"
require "pry"

WIDTH = 600
HEIGHT = 600

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
      if rel.abs < 10
        b1.change(10,rel.arg,0.1)
        b2.change(10,(-rel).arg,0.1)
      end
    end
  end

  # 集合
  def cohere
    return if empty?
    center = map(&:pos).avg
    each do |b|
      arg = (center - b.pos).arg
      b.change(10,arg,0.05)
    end
  end

  # 整列
  def align
    each do |boid|
      g = group(boid,50)
      next if g.empty?
      group_vel = g.map(&:vel).avg
      boid.change(*group_vel.polar,0.2)
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
    boids.group(self,200) do |targets|
      center = targets.map(&:pos).avg
      change(10,(center - @pos).arg,0.1)
    end
    super()

    # 食べる
    boids.reject! do |b|
      (b.pos - @pos).abs < 16
    end

    # 逃げる
    boids.group(self,100) do |targets|
      targets.each do |boid|
        rel = (boid.pos - @pos)
        arg = rel.arg
        if (boid.vel/rel).imag > 0
          arg += Math::PI/2
        else
          arg -= Math::PI/2
        end
        boid.change(30,arg,0.3)
      end
    end
  end
end

# ウィンドウ
class Scene < Gosu::Window
  def initialize
    super WIDTH,HEIGHT,false
    @enemy = Enemy.new(Gosu::Image.new(self,"shark.png",false))
    @boids = Boids.new
    @img = Gosu::Image.new(self,"delta.png",false)
    300.times{@boids << Boid.new(@img,rand(360),5,rand(WIDTH),rand(HEIGHT))}
    @font = Gosu::Font.new(self,Gosu::default_font_name,20)
  end

  def update
    @boids.update
    @enemy.update(@boids)
  end

  def draw
    @boids.draw
    @enemy.draw
    @font.draw("number of boid: #{@boids.size}",10,10,ZOrder::UI,1.0,1.0,0xffffff00)
  end
end

module ZOrder
  Background,Stars,Player,UI = *0..3
end

scene = Scene.new
scene.show