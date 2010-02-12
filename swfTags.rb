require 'BStruct'
require 'sexp_processor'
require 'Abc'

class << BStruct
	def rect(*syms)
		add :rect_dec, :rect_enc, syms
	end
	def rect_dec(obj, data)
		data.align
		nbits = data.ubits 5
		s(:rect, 
			data.sbits(nbits), data.sbits(nbits), 
			data.sbits(nbits), data.sbits(nbits))
	end
	
	def tags(*syms)
		add :tags_dec, :tags_enc, syms
	end
	def tags_dec(obj, data)
		tags = []
		while true
			tagCodeAndLength = data.next(2).uint16
			type = tagCodeAndLength >> 6
			break if type == 0
			tagLength = tagCodeAndLength & 0x3F
			if tagLength == 0x3F then
				tdata = data.next(data.next(4).uint32)
			else
				tdata = data.next(tagLength)
			end
			
			if $tagTypes.has_key? type then
				tag = $tagTypes[type].handleRaw tdata
				tags.add(tag) if tag != nil
			else
				puts 'Unknown tag type: ' + type.to_s
			end
		end
		
		s :tags, *tags
	end
	
	def uint1(*syms)
		add :uint1_dec, :uint1_enc, syms
	end
	def uint1_dec(obj, data)
		data.ubits 1
	end
	
	def rest(*syms)
		add :rest_dec, :rest_enc, syms
	end
	def rest_dec(obj, data)
		data.rest
	end
end

def matrixUnpack(data)
	hasScale = data.ubits 1
	if hasScale == 1 then
		nScaleBits = data.ubits 5
		scale = s :scale, data.fbits(nScaleBits), data.fbits(nScaleBits)
	else
		scale = nil
	end
	
	hasRotate = data.ubits 1
	if hasRotate == 1 then
		nRotateBits = data.ubits 5
		rotate = s :rotate, data.fbits(nRotateBits), data.fbits(nRotateBits)
	else
		rotate = nil
	end
	
	nTranslateBits = data.ubits 5
	translate = s :translate, data.sbits(nTranslateBits), data.sbits(nTranslateBits)
	
	s :matrix, scale, rotate, translate
end

def colorTransformUnpack(data)
	data.align
	hasAddTerms = data.ubits 1
	hasMultTerms = data.ubits 1
	nBits = data.ubits 4
	if hasMultTerms == 1 then
		mult = s :colorMult, data.sbits(nBits), data.sbits(nBits), data.sbits(nBits)
	else mult = nil
	end
	if hasAddTerms == 1 then
		add = s :colorAdd, data.sbits(nBits), data.sbits(nBits), data.sbits(nBits)
	else add = nil
	end
	
	s :colorTransform, add, mult
end

def clipEventFlagsUnpack(data)
	if $version <= 5 then data.next(2).uint16
	else data.next(4).uint32
	end
end

def clipActionsUnpack(data)
	data.align
	
	data.next(2).uint16
	allEventFlags = clipEventFlagsUnpack data
	
	while true
		flags = clipEventFlagsUnpack data
		break if flags == 0
		
		size = data.next(4).uint32
		keyPressFlag = (flags >> 17) & 1
		if keyPressFlag == 1 then keyCode = data.next.uint8
		else keyCode = nil
		end
		
		if size > 1 then
			puts 'Actions :('
			0/0
		end
	end
end

def rgbUnpack(data)
	s :rgb, data.next.uint8, data.next.uint8, data.next.uint8
end

def rgbaUnpack(data)
	s :rgba, data.next.uint8, data.next.uint8, data.next.uint8, data.next.uint8
end

def gradientRecordUnpack(data, version)
	ratio = data.next.uint8
	if version >= 3 then color = rgbaUnpack data
	else color = rgbUnpack data
	end
	
	s :gradientPoint, ratio, color
end

def gradientUnpack(data, version=3)
	data.align
	spreadMode = data.ubits 2
	interpolationMode = data.ubits 2
	numGradients = data.ubits 4
	
	s :gradient, *((0...numGradients).map {|i| gradientRecordUnpack data, version })
end

def fillStyleUnpack(data, version)
	fillStyleType = data.next.uint8
	
	if fillStyleType == 0x00 then
		if version >= 3 then s :solidFill, rgbaUnpack(data)
		else s :solidFill, rgbUnpack(data)
		end
	elsif fillStyleType & 0x10 == 0x10 then
		matrix = matrixUnpack data
		case fillStyleType
		when 0x10 then
			s :linearGradient, matrix, gradientUnpack(data, version)
		when 0x12 then
			s :radialGradient, matrix, gradientUnpack(data, version)
		when 0x13 then
			s :focalRadialGradient, matrix, focalGradientUnpack(data, version)
		end
	elsif fillStyleType & 0x40 == 0x40 then
		id = data.next(2).uint16
		matrix = matrixUnpack data
		type = [
				:repeatingBitmap, 
				:clippedBitmap, 
				:nsRepeatingBitmap, 
				:nsClippedBitmap
			][fillStyleType & 0xF]
		s type, id, matrix
	else nil
	end
end

def fillStyleArrayUnpack(data, version)
	count = data.next.uint8
	count = data.next(2).uint16 if count == 0xFF and version >= 2
	
	foo = s :fillStyles, *((0...count).map {|i| fillStyleUnpack data, version })
end

def morphGradientRecordUnpack(data)
	startRatio = data.next.uint8
	startColor = rgbaUnpack data
	endRatio = data.next.uint8
	endColor = rgbaUnpack data
	
	s :morphGradientPoint, startRatio, endRatio, startColor, endColor
end

def morphGradientUnpack(data)
	numGradients = data.next.uint8
	s :morphGradient, *((0...numGradients).map {|i| morphGradientRecordUnpack data })
end

def morphFillStyleUnpack(data)
	fillStyleType = data.next.uint8
	
	if fillStyleType == 0x00 then
		s :morphSolidFill, rgbaUnpack(data), rgbaUnpack(data)
	elsif fillStyleType & 0x10 == 0x10 then
		startMatrix = matrixUnpack data
		endMatrix = matrixUnpack data
		case fillStyleType
		when 0x10 then
			s :morphLinearGradient, startMatrix, endMatrix, morphGradientUnpack(data)
		when 0x12 then
			s :morphRadialGradient, startMatrix, endMatrix, morphGradientUnpack(data)
		end
	elsif fillStyleType & 0x40 == 0x40 then
		id = data.next(2).uint16
		startMatrix = matrixUnpack data
		endMatrix = matrixUnpack data
		type = [
				:morphRepeatingBitmap, 
				:morphClippedBitmap, 
				:morphNsRepeatingBitmap, 
				:morphNsClippedBitmap
			][fillStyleType & 0xF]
		s type, id, startMatrix, endMatrix
	else nil
	end
end

def morphFillStyleArrayUnpack(data)
	count = data.next.uint8
	count = data.next(2).uint16 if count == 0xFF
	
	s :morphFillStyles, *((0...count).map {|i| morphFillStyleUnpack data })
end

def lineStyleUnpack(data, version)
	width = data.next(2).uint16
	if version >= 3 then
		color = rgbaUnpack data
	else color = rgbUnpack data
	end
	
	s :lineStyle, width, color
end

def capStyle(data)
	[:round, :none, :square][data.ubits 2]
end

def lineStyle2Unpack(data, version)
	width = data.next(2).uint16
	startCapStyle = capStyle data
	joinStyle = [:round, :bevel, :miter][data.ubits 2]
	hasFill = data.ubits 1
	noHScale = data.ubits 1
	noVScale = data.ubits 1
	pixelHinting = data.ubits 1
	reserved = data.ubits 5
	noClose = data.ubits 1
	endCapStyle = capStyle data
	
	if joinStyle == :miter then
		miterLimitFactor = data.next(2).uint16
	else miterLimitFactor = nil
	end
	
	if hasFill == 0 then
		fill = rgbaUnpack data
	else fill = fillStyleUnpack data, 4
	end
	
	s :lineStyle2, width, startCapStyle, endCapStyle, fill
end

def lineStyleArrayUnpack(data, version)
	count = data.next.uint8
	count = data.next(2).uint16 if count == 0xFF
	
	if version >= 4 then
		s :lineStyles2, *((0...count).map {|i| lineStyle2Unpack data, version })
	else
		s :lineStyles, *((0...count).map {|i| lineStyleUnpack data, version })
	end
end

def morphLineStyleUnpack(data)
	startWidth = data.next(2).uint16
	endWidth = data.next(2).uint16
	startColor = rgbaUnpack data
	endColor = rgbaUnpack data
	
	s :morphLineStyle, startWidth, endWidth, startColor, endColor
end

def morphLineStyle2Unpack(data)
	startWidth = data.next(2).uint16
	endWidth = data.next(2).uint16
	startCapStyle = capStyle data
	joinStyle = [:round, :bevel, :miter][data.ubits 2]
	hasFill = data.ubits 1
	noHScale = data.ubits 1
	noVScale = data.ubits 1
	pixelHinting = data.ubits 1
	reserved = data.ubits 5
	noClose = data.ubits 1
	endCapStyle = capStyle data
	
	if joinStyle == :miter then
		miterLimitFactor = data.next(2).uint16
	else miterLimitFactor = nil
	end
	
	if hasFill == 0 then
		fill = s :morphLineFill, rgbaUnpack(data), rgbaUnpack(data)
	else fill = morphFillStyleUnpack data
	end
	
	s :morphLineStyle, startWidth, endWidth, startCapStyle, endCapStyle, fill
end

def morphLineStyleArrayUnpack(data, version)
	count = data.next.uint8
	count = data.next(2).uint16 if count == 0xFF
	
	if version == 1 then
		s :morphLineStyles, *((0...count).map {|i| morphLineStyleUnpack data })
	else
		s :morphLineStyles, *((0...count).map {|i| morphLineStyle2Unpack data })
	end
end

def shapeUnpack(data, version)
	data.align
	fillBits = data.ubits 4
	lineBits = data.ubits 4
	
	records = []
	while true
		typeFlag = data.ubits 1
		
		if typeFlag == 0 then
			newStylesFlag = data.ubits 1
			lineStyleFlag = data.ubits 1
			fillStyle1Flag = data.ubits 1
			fillStyle0Flag = data.ubits 1
			moveToFlag = data.ubits 1
			break if not [newStylesFlag, lineStyleFlag, fillStyle1Flag, fillStyle0Flag, moveToFlag].include? 1
			
			if moveToFlag == 1 then
				moveBits = data.ubits 5
				move = s :move, data.sbits(moveBits), data.sbits(moveBits)
			else move = nil
			end
			
			if fillStyle0Flag == 1 then
				fillStyle0 = data.ubits fillBits
			else fillStyle0 = nil
			end
			if fillStyle1Flag == 1 then
				fillStyle1 = data.ubits fillBits
			else fillStyle1 = nil
			end
			
			if lineStyleFlag == 1 then
				lineStyle = data.ubits lineBits
			else lineStyle = nil
			end
			
			if newStylesFlag == 1 then
				newFillStyles = fillStyleArrayUnpack data, version
				newLineStyles = lineStyleArrayUnpack data, version
				
				fillBits = data.ubits 4
				lineBits = data.ubits 4
			else
				newFillStyles = nil
				newLineStyles = nil
			end
			
			records.add s(:styleChangeRecord, move, fillStyle0, fillStyle1, lineStyle, newFillStyles, newLineStyles)
		else
			straightFlag = data.ubits 1
			if straightFlag == 1 then
				numBits = data.ubits(4) + 2
				generalLineFlag = data.ubits 1
				
				vertLineFlag = data.ubits 1 if generalLineFlag == 0
				
				if generalLineFlag == 1 or vertLineFlag == 0 then
					deltaX = data.sbits numBits
				else deltaX = 0
				end
				if generalLineFlag == 1 or vertLineFlag == 1 then
					deltaY = data.sbits numBits
				else deltaY = 0
				end
				
				records.add s(:straightLineRecord, deltaX, deltaY)
			else
				numBits = data.ubits(4) + 2
				
				controlDeltaX = data.sbits numBits
				controlDeltaY = data.sbits numBits
				anchorDeltaX = data.sbits numBits
				anchorDeltaY = data.sbits numBits
				
				records.add s(:curvedLineRecord, controlDeltaX, controlDeltaY, anchorDeltaX, anchorDeltaY)
			end
		end
	end
	
	s :shapeDef, *records
end

def shapeWithStyleUnpack(data, version)
	fillStyleArray = fillStyleArrayUnpack data, version
	lineStyleArray = lineStyleArrayUnpack data, version
	
	shape = shapeUnpack data, version
	
	s :shapeWithStyle, fillStyleArray, lineStyleArray, shape
end

$tagTypes = {}
def tag(id, name, &block)
	clsname = name.to_s + 'Tag'
	
	if block == nil then
		struct clsname do
			def handle
				nil
			end
		end
	else
		struct clsname, &block
	end
	eval %Q{
		class << #{clsname}
			def handleRaw(data)
				arr = #{clsname}.unpack(Buffer.new data).handle
				arr = [] if arr == nil
				arr = [arr] if not arr.is_a? Array
				s :#{name}, *arr
			end
		end
	}
	$tagTypes[id] = eval(clsname)
end

tag 1, :ShowFrame

tag 2, :DefineShape do
	uint16 :shapeId
	rect :shapeBounds
	custom :shape do |obj, data|
		shapeWithStyleUnpack data, 1
	end
	
	def handle
		s @shapeId, @shapeBounds, @shape
	end
end

tag 9, :SetBackgroundColor do
	uint8 :r, :g, :b
	
	def handle
		s @r, @g, @b
	end
end

#tag 11, :DefineText do
#	uint16 :characterId
#	rect :textBounds
#	#matrix :textMatrix
#	#uint8 :glyphBits, :advanceBits
#	# XXX: FINISHME
#	
#	def handle
#		s @characterId
#	end
#end

tag 12, :DoAction do
	# XXX: FINISHME
	
	def handle
	end
end

tag 24, :Protect

tag 26, :PlaceObject2 do
	uint1 :hasClipActions, :hasClipDepth, :hasName, :hasRatio
	uint1 :hasColorTransform, :hasMatrix, :hasCharacter, :move
	
	uint16 :depth
	custom :characterId do |obj, data|
		if obj.hasCharacter == 1 then data.next(2).uint16
		else nil
		end
	end
	custom :matrix do |obj, data|
		if obj.hasMatrix == 1 then matrixUnpack data
		else nil
		end
	end
	custom :colorTransform do |obj, data|
		if obj.hasColorTransform == 1 then colorTransformUnpack data
		else nil
		end
	end
	custom :ratio do |obj, data|
		if obj.hasRatio == 1 then data.next(2).uint16
		else nil
		end
	end
	custom :name do |obj, data|
		if obj.hasName == 1 then data.string
		else nil
		end
	end
	custom :clipDepth do |obj, data|
		if obj.hasClipDepth == 1 then data.next(2).uint16
		else nil
		end
	end
	custom :clipActions do |obj, data|
		if obj.hasClipActions == 1 then clipActionsUnpack data
		else nil
		end
	end
	
	def handle
		s @depth, @characterId, @matrix, @colorTransform, @ratio, @name
	end
end

tag 28, :RemoveObject2 do
	uint16 :depth
	
	def handle
		@depth
	end
end

tag 32, :DefineShape3 do
	uint16 :shapeId
	rect :shapeBounds
	custom :shape do |obj, data|
		shapeWithStyleUnpack data, 3
	end
	
	def handle
		s @shapeId, @shapeBounds, @shape
	end
end

#tag 34, :DefineButton2 do
#	uint16 :buttonId
#	uint8 :trackAsMenu
#	uint16 :actionOffset
#	# XXX: FINISHME
#	
#	def handle
#		s @buttonId, @trackAsMenu
#	end
#end

#tag 37, :DefineEditText do
#	uint16 :characterId
#	rect :bounds
#	uint1 :hasText, :wordWrap, :multiLine, :password, :readOnly, :hasTextColor
#	uint1 :hasMaxLength, :hasFont, :hasFontClass, :autoSize, :hasLayout, :noSelect
#	uint1 :border, :wasStatic, :html, :useOutlines
#	# XXX: FINISHME
#	
#	def handle
#		s @characterId, @bounds
#	end
#end

tag 39, :DefineSprite do
	uint16 :spriteId, :frameCount
	
	tags :controlTags
	
	def handle
		s @spriteId, @frameCount, @controlTags
	end
end

tag 41, :AuditInfo # XXX: Need information

tag 43, :FrameLabel do
	string :label
	
	def handle
		@label
	end
end

tag 46, :DefineMorphShape do
	uint16 :characterId
	rect :startBounds, :endBounds
	uint32 :offset
	custom :morphFillStyles do |obj, data|
		morphFillStyleArrayUnpack data
	end
	custom :morphLineStyles do |obj, data|
		morphLineStyleArrayUnpack data, 1
	end
	custom :startEdges do |obj, data|
		shapeUnpack data, 3
	end
	custom :endEdges do |obj, data|
		shapeUnpack data, 3
	end
	
	def handle
		s @characterId, @startBounds, @endBounds, @morphFillStyles, @morphLineStyles, @startEdges, @endEdges
	end
end

#tag 48, :DefineFont2 do
#	uint16 :fontId
#	uint1 :hasLayout, :shiftJIS, :smallText, :ANSI, :wideOffsets, :wideCodes
#	uint1 :italic, :bold
#	uint8 :languageCode
#	uint8 :fontNameLen
#	string :fontName*:fontNameLen
#	
#	uint16 :numGlyphs
#	# XXX: FINISHME
#	
#	def handle
#		s @fontId, @fontName
#	end
#end

tag 56, :ExportAssets do
	uint16 :count, :tag1
	string :name
	
	def handle
		s @count, @tag1, @name
	end
end

tag 65, :ScriptLimits do
	uint16 :maxRecursionDepth, :scriptTimeoutSeconds
	
	def handle
		s @maxRecursionDepth, @scriptTimeoutSeconds
	end
end

tag 69, :FileAttributes do
	uint1 :reserved, :useDirectBlit, :useGPU, :hasMetadata
	uint1 :actionscript3, :reserved, :reserved, :useNetwork
	
	def handle
		s @useDirectBlit, @useGPU, @hasMetadata, @actionscript3, @useNetwork
	end
end

tag 76, :SymbolClass do
	uint16 :numSymbols
	custom :symbols do |obj, data|
		symbols = (0...obj.numSymbols).map {|i|
				s :symbolClassDef, data.next(2).uint16, data.string
			}
		s *symbols
	end
	
	def handle
		@symbols
	end
end

tag 77, :Metadata do
	string :metadata
	
	def handle
		@metadata
	end
end

tag 82, :DoABC do
	uint32 :flags
	string :name
	rest :bytecode
	
	def handle
		s @flags==1, @name, Abc.load(Buffer.new @bytecode)
	end
end

tag 83, :DefineShape4 do
	uint16 :characterId
	rect :shapeBounds, :edgeBounds
	custom :shapes do |obj, data|
		data.align
		reserved = data.ubits 5
		@usesFillWindingRule = data.ubits(1)==1
		@usesNonScalingStrokes = data.ubits(1)==1
		@usesScalingStrokes = data.ubits(1)==1
		
		shapeWithStyleUnpack data, 4
	end
	
	def handle
		s @characterId, @shapeBounds, @edgeBounds, @shapes
	end
end

tag 86, :DefineSceneAndFrameLabelData do
	custom :scenes do |obj, data|
		count = data.encUint32
		(0...count).map do |i|
			offset = data.encUint32
			name = data.string
			[offset, name]
		end
	end
	
	def handle
		s *@scenes
	end
end
