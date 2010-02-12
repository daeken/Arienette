require 'Zlib'
require 'BStruct'
require 'swfTags'

struct :SwfHeader do
	string :compressed*1
	magic 'WS'
	
	uint8 :version
	uint32 :length
end

struct :SwfHeaderRest do
	rect :frameSize
	uint16 :frameRate
	uint16 :frameCount
	
	tags :tags
end

class Swf
	class << self
		def load(fn)
			data = File.new(fn, 'rb').read
			@data = Buffer.new data
			
			header = SwfHeader.unpack @data
			$version = header.version
			#if $version < 9 then
			#	puts 'SWF version must by >= 9.  Version: ' + $version.to_s
			#	return
			#end
			if header.compressed == 'C' then
				data = Zlib::Inflate.inflate @data.rest
				@data = Buffer.new data
			end
			
			headerRest = SwfHeaderRest.unpack @data
			tags = headerRest.tags
			tags.shift
			
			s :tags, headerRest.frameSize, headerRest.frameRate, *tags
		end
	end
end
