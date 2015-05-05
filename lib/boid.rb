require "gosu"

WIDTH = 640
HEIGHT = 480

# 個体クラス
class Boid
  attr_accessor :pos,:vel

  def initialize(img=nil,t=90,r=5,x=(WIDTH/2),y=(HEIGHT/2))
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

  def change(v,p)
    @vel *= (v/@vel)**p
  end
end

# 群れクラス
class Boids < Array

  # 更新
  def update
    if size > 0
      separate()
      cohere()
      align()
    end
    each(&:update)
  end

  def draw; each(&:draw); end

  # 分離
  def separate
    combination(2) do |b1,b2|
      rel = b1.pos - b2.pos
      if rel.abs < 10
        b1.change(Complex.polar(10,rel.arg),0.1)
        b2.change(Complex.polar(10,(-rel).arg),0.1)
      end
    end
  end

  # 集合
  def cohere
    center = map(&:pos).inject{|a,b|a+=b}/size
    each do |b|
      arg = (center - b.pos).arg
      b.change(Complex.polar(10,arg),0.05)
    end
  end

  # 整列
  def align
    each do |b1|
      group = select{|b2|(b2.pos - b1.pos).abs < 50}
      if group.size > 0
        group_vel = group.map(&:vel).inject{|a,b|a+=b}/group.size
        b1.change(group_vel,0.2)
      end
    end
  end
end

# ウィンドウ
class Window < Gosu::Window
  def initialize
    super WIDTH,HEIGHT,false
    @enemy = Boid.new(Gosu::Image.new(self,"shark.png",false))
    @boids = Boids.new
    @img = Gosu::Image.new(self,"delta.png",false)
  end

  def update
    # 捕食者
    targets = @boids.select{|b|(b.pos - @enemy.pos).abs < 200}
    if targets.size > 0
      center = targets.map(&:pos).inject{|a,b|a+=b}/targets.size
      @enemy.change(Complex.polar(10,(center - @enemy.pos).arg),0.1)
    end
    @enemy.update

    # 捕食者を回避
    targets.each do |b|
      arg = (b.pos - @enemy.pos).arg
      if (b.vel/(b.pos - @enemy.pos)).imag > 0
        arg += Math::PI/2
      else
        arg -= Math::PI/2
      end
      b.change(Complex.polar(30,arg),0.3)
    end

    # 群れの行動
    @boids << Boid.new(@img,rand(360),5,rand(WIDTH),rand(HEIGHT)) if @boids.size < 100
    @boids.update

  end
  def draw
    @boids.draw
    @enemy.draw
  end
end

window = Window.new
window.show