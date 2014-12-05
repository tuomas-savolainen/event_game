class Vector
	def initialize(x, y)
		@x = x
		@y = y
	end
	attr_accessor :x
	attr_accessor :y

	def +(b)
		Vector.new(@x + b.x, @y + b.y)
	end

	def -(b)
		Vector.new(@x -b.x, @y - b.y)
	end

	def *(scalar)
		Vector.new(@x *scalar, @y *scalar)
	end

	def length
		Math.sqrt(@x**2 + @y**2)
	end

	#make the vector unit length
	def normalize
		scale = length()
		x = scale > 0 ? @x / scale : 0
		y = scale > 0 ? @y / scale : 0
		Vector.new(x, y)
	end
	

end