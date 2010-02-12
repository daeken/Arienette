class Fill
end

class SolidFill < Fill
	def initialize(r, g, b, a)
		@color = [color(r), color(g), color(b), color(a)]
	end
	
	def set
		glColor4f *@color
	end
end

class LinearGradientFill < Fill
	def initialize(matrix, points)
		pp matrix, points
	end
	
	def set
	end
end

class RadialGradientFill < Fill
	def initialize(matrix, points)
		pp matrix, points
	end
	
	def set
	end
end

class MorphSolidFill < Fill
	def initialize(a, b)
		@a = a
		@b = b
	end
	
	def morph(ratio)
		SolidFill.new m(ratio, @a[0], @b[0]), m(ratio, @a[1], @b[1]), m(ratio, @a[2], @b[2]), m(ratio, @a[3], @b[3])
	end
end
