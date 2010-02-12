class MorphShape
	def initialize(startBounds, endBounds, fillStyles, startEdges, endEdges)
		startShape = Shape.new(startBounds, nil, startEdges).edges
		endShape = Shape.new(endBounds, nil, endEdges).edges
		@ratio = 0
		
		@fillStyles = fillStyles
		@startShape = []
		@endShape = []
		
		(0...startShape.size).each do |i|
			aPen, aEdge = startShape[i]
			bPen, bEdge = endShape[i]
			
			if aEdge.size == 4 and bEdge.size == 2 then
				@startShape.add [aPen, aEdge]
				@endShape.add [bPen, [half(bPen[0], bEdge[0]), half(bPen[1], bEdge[1]), bEdge[0], bEdge[1]]]
			elsif aEdge.size == 2 and bEdge.size == 4 then
				@endShape.add [bPen, bEdge]
				@startShape.add [aPen, [half(aPen[0], aEdge[0]), half(aPen[1], aEdge[1]), aEdge[0], aEdge[1]]]
			else
				@startShape.add [aPen, aEdge]
				@endShape.add [bPen, bEdge]
			end
		end
	end
	
	def matrix(set=nil)
		@matrix = set if set != nil
		@matrix
	end
	
	def ratio(set=nil)
		@ratio = set if set != nil
		@ratio
	end
	
	def render
		startShape = @startShape
		endShape = @endShape
		ratio = @ratio
		fill = @fillStyles
		draw @matrix do
			setFill fill[0].morph(ratio)
			(0...startShape.size).each do |i|
				aPen, aEdge = startShape[i]
				bPen, bEdge = endShape[i]
				
				if aEdge.size == 2 then
					point *midpoint(ratio, aPen, bPen)
					point *midpoint(ratio, aEdge, bEdge)
				else
					drawCurve(
						midpoint(ratio, aPen, bPen), 
						midpoint(ratio, aEdge, bEdge), 
						midpoint(ratio, aEdge, bEdge, 2)
					)
				end
			end
		end
	end
	
	def half(a, b)
		a + ((b - a) * 0.5)
	end
end

class Shape
	def initialize(bounds, fillStyles, edges)
		@edges = []
		@pen = [0, 0]
		@fillStyles = fillStyles
		
		self.instance_eval &edges
	end
	
	def edges
		@edges
	end
	
	def matrix(set=nil)
		@matrix = set if set != nil
		@matrix
	end
	
	def render
		edges = @edges
		fill = @fillStyles
		draw @matrix do
			setFill fill[0] if fill != nil
			edges.each do |pen, edge|
				first = pen if first == nil
				if edge.size == 2 then
					point pen[0], pen[1]
					point edge[0], edge[1]
				else
					drawCurve(
						pen, 
						[edge[0], edge[1]], 
						[edge[2], edge[3]]
					)
				end
			end
		end
	end
	
	def curvedLine(cX, cY, aX, aY)
		@edges.add [@pen, [@pen[0] + cX, @pen[1] + cY, @pen[0] + cX + aX, @pen[1] + cY + aY]]
		@pen = [@pen[0] + cX + aX, @pen[1] + cY + aY]
	end
	
	def move(x, y)
		@pen = [@pen[0]+x, @pen[1]+y]
	end
	
	def straightLine(x, y)
		pen = @pen
		@pen = [@pen[0] + x, @pen[1] + y]
		@edges.add [pen, @pen]
	end
end
