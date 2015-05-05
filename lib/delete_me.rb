require "RMagick"

canvas = Magick::Image.new(32,32){self.background_color="black"}
dr = Magick::Draw.new
dr.stroke('red')
dr.stroke_width(4)
dr.line(0,4,16,8)
dr.line(0,12,16,8)
dr.draw(canvas)

canvas.write("delta.png")
