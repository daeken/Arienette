require 'sexpTransform'

class RubyBackend < SexpTransform
	rename :unifytags, :foo
	
	transform :backgroundColor do |(_, r, g, b)|
		%Q{
			backgroundColor #{r}, #{g}, #{b}
		}
	end
	
	transform :gradient do |*points|
		points = points.map do |_, ratio, color|
			"[#{ratio}, #{run color}]"
		end
		
		points.join ', '
	end
	
	transform :linearGradient do |matrix, gradient|
		"LinearGradientFill.new(#{run matrix}, [#{run gradient}])"
	end
	
	transform :matrix do |scale, rotate, translate|
		scale = [0, 1, 1] if scale == nil
		rotate = [0, 0, 0] if rotate == nil
		translate = [0, 0, 0] if translate == nil
		%Q{
			[
				#{scale[1]}, #{rotate[1]}, 0, 0,
				#{rotate[2]}, #{scale[2]}, 0, 0, 
				0, 0, 1, 0, 
				#{translate[1]}, #{translate[2]}, 0, 1
			]}
	end
	
	transform :morphSolidFill do |s, e|
		"MorphSolidFill.new(#{run s}, #{run e})"
	end
	
	transform :morphShape do |character, startBounds, endBounds, fillStyles, lineStyles, startEdges, endEdges|
		startEdgesCode = compileEdges startEdges
		endEdgesCode = compileEdges endEdges
		fillStyles = compileFillStyles fillStyles
		
		%Q{
			morphShape(
				#{character}, 
				[#{startBounds[1]}, #{startBounds[2]}, #{startBounds[3]}, #{startBounds[4]}], 
				[#{endBounds[1]}, #{endBounds[2]}, #{endBounds[3]}, #{endBounds[4]}],
				#{fillStyles}, 
				lambda {
					#{startEdgesCode}
				}, 
				lambda {
					#{endEdgesCode}
				}
			)
		}
	end
	
	transform :place do |character, depth, matrix, ratio|
		%Q{
			place(#{denil character}, #{denil depth}, #{run matrix}, #{denil ratio})
		}
	end
	
	transform :radialGradient do |matrix, gradient|
		"RadialGradientFill.new(#{run matrix}, [#{run gradient}])"
	end
	
	transform :rgb do |r, g, b|
		"[#{r}, #{g}, #{b}, 255]"
	end
	
	transform :rgba do |r, g, b, a|
		"[#{r}, #{g}, #{b}, #{a}]"
	end
	
	drop :rect
	
	transform :remove do |depth|
		%Q{
			remove #{depth}
		}
	end
	
	transform :shape do |character, bounds, fill, line, shape|
		edgesCode = compileEdges shape
		fillStyles = compileFillStyles fill
		
		%Q{
			shape(
				#{character}, 
				[#{bounds[1]}, #{bounds[2]}, #{bounds[3]}, #{bounds[4]}], 
				#{fillStyles}, 
				lambda {
					#{edgesCode}
				}
			)
		}
	end
	
	transform :show do
		'show'
	end
	
	transform :solidFill do |_, r, g, b, a=255.0|
		"SolidFill.new(#{r}, #{g}, #{b}, #{a})"
	end
	
	transform :sprite do |character, frames, actions|
		actionCode = compileSpriteActions actions
		
		%Q{
			sprite #{character} do
				#{actionCode}
			end
		}
	end
	
	transform :styleChangeRecord do |move, fillStyle0, fillStyle1, lineStyle, newFillStyles, newLineStyles|
		emit "move #{move[1]}, #{move[2]}" if move != nil
		
		emit "fillStyle0 #{fillStyle0}" if fillStyle0 != nil
		emit "fillStyle1 #{fillStyle1}" if fillStyle1 != nil
		emit "lineStyle #{lineStyle}" if lineStyle != nil
	end
	
	transform :straightLineRecord do |deltaX, deltaY|
		emit "straightLine #{deltaX}, #{deltaY}"
	end
	
	transform :curvedLineRecord do |controlX, controlY, anchorX, anchorY|
		emit "curvedLine #{controlX}, #{controlY}, #{anchorX}, #{anchorY}"
	end
	
	class << self
		def compileEdges(edges)
			edgeCode = edges[1...edges.size].map do |edge|
				run edge
			end
			
			edgeCode.join "\n"
		end
		
		def compileFillStyles(fill)
			return 'nil' if fill == nil
			
			fillCode = fill[1...fill.size].map do |fill|
				run fill
			end
			
			'[' + fillCode.join(', ') + ']'
		end
		
		def compileSpriteActions(actions)
			actions = run actions
			actions[1...actions.size].join "\n"
		end
		
		def compile(orig)
			code = run orig
			
			lines = code[1...code.size].map do |elem|
				if elem.is_a? String then
					sublines = elem.split "\n"
					
					sublines.map! {|line| line.strip }
					sublines.reject! {|line| line.empty? }
					sublines.join "\n"
				else ''
				end
			end
			lines.reject! {|line| line.empty? }
			
			code = lines.join "\n"
			
			_, frameSize, frameRate = orig
			frameSize.shift
			frameSize = "[#{frameSize.shift}, #{frameSize.shift}, #{frameSize.shift}, #{frameSize.shift}]"
			
			code = %Q{
				require 'FlashRuntime/movie'
				
				movie #{frameSize}, #{frameRate} do
					#{code}
				end
			}
			
			code.split("\n").map {|line| line.strip }.join("\n")
		end
		
		def denil(x)
			if x == nil then 'nil'
			else x
			end
		end
	end
end
