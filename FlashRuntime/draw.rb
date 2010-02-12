class Draw
	def initialize
		@tess = gluNewTess
		gluTessProperty @tess, GLU_TESS_WINDING_RULE, GLU_TESS_WINDING_NONZERO
		#gluTessProperty @tess, GLU_TESS_BOUNDARY_ONLY, GL_TRUE
		
		callback GLU_TESS_BEGIN do |mode| glBegin(mode) end
		callback GLU_TESS_END do glEnd end
		
		callback GLU_TESS_COMBINE do |coords, d, w| coords end
		callback GLU_TESS_VERTEX do |vert| glVertex3dv vert end
		
		callback GLU_TESS_ERROR do |type| puts 'Error: ' + type.to_s end
	end
	
	def callback(func, &block)
		gluTessCallback @tess, func, block
	end
	
	def draw(matrix, &block)
		@fill = nil
		
		glPushMatrix
		glMultMatrix matrix if matrix != nil
		
		gluTessBeginPolygon @tess, nil
		gluTessBeginContour @tess
		
		self.instance_eval &block
		
		gluTessEndContour @tess
		gluTessEndPolygon @tess
		
		glPopMatrix
	end
	
	def setFill(fill)
		@fill = fill
		@fill.set if @fill != nil
	end
	
	def point(x, y)
		v = [x.to_f, y.to_f, 0.0]
		gluTessVertex @tess, v, v
	end
	
	def drawCurve(pen, control, anchor)
		steps = 100
		delta = 1.0 / steps
		point *pen
		(1...steps).each do |t|
			t *= delta
			
			q0 = midpoint t, pen, control
			q1 = midpoint t, control, anchor
			
			point *midpoint(t, q0, q1)
		end
		point *anchor
	end
	
	def midpoint(t, a, b, off=0)
		[m(t, a[off], b[off]), m(t, a[off+1], b[off+1])]
	end
end

$draw = Draw.new
def draw(matrix, &block)
	$draw.draw matrix, &block
end
