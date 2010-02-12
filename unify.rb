require 'sexpTransform'
require 'abcUnify'

class Unify < SexpTransform
	ignore :fillStyles, :lineStyles, :matrix, :morphFillStyles, :morphLineStyles, :rgb, :rgba, :rect, :shapeDef
	rename :tags, :unifytags
	
	drop :FileAttributes
	drop :Metadata
	drop :ScriptLimits
	drop :AuditInfo
	drop :ExportAssets
	drop :Protect
	drop :DoAction
	drop :DefineSceneAndFrameLabelData
	
	rename :DefineMorphShape, :morphShape
	rename :DoABC, :doABC
	
	transform :DefineShape do |character, bounds, (_, fill, line, shape)|
		s :shape, character, bounds, fill, line, shape
	end
	
	transform :DefineShape4 do |character, shapeBounds, edgeBounds, (_, fill, line, shape)|
		s :shape, character, shapeBounds, fill, line, shape
	end
	
	transform :DefineSprite do |character, frameCount, actions|
		s :sprite, character, frameCount, run(actions)
	end
	
	transform :DoABC do |lazy, name, bytecode|
		pp bytecode
		s :doABC, lazy, name#, ABCUnify.run(bytecode)
	end
	
	transform :FrameLabel do |label|
		s :label, label
	end
	
	transform :PlaceObject2 do |depth, character, matrix, colorTransform, ratio, name|
		s :place, character, depth, matrix, ratio
	end
	
	transform :RemoveObject2 do |depth|
		s :remove, depth
	end
	
	transform :SetBackgroundColor do |r, g, b|
		s :backgroundColor, s(:rgb, r, g, b)
	end
	
	transform :ShowFrame do
		s :show
	end
	
	transform :SymbolClass do |*symbols|
		symbols.each do |_, symbol, name|
		  emit s(:symbolClass, symbol, name)
		end
		
		nil
	end
end
