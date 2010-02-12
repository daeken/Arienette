require 'pp'

class Array
	def add(val)
		self[self.count] = val
	end
end

class SizedSymbol
	def initialize(sym, size)
		@sym = sym
		@size = size
	end
	
	def size
		@size
	end
	
	def size?
		@size != nil
	end
	
	def to_s
		@sym.to_s
	end
end

class Symbol
	def *(right)
		SizedSymbol.new(self, right)
	end
	
	def size
		nil
	end
	
	def size?
		false
	end
end

class Buffer
	def initialize(data, off=[0, 0])
		@data = data
		@off = off
	end
	
	def off
		@off
	end
	
	def size
		@data.size
	end
	
	def has_left?
		@off[0] < @data.size
	end
	
	def rest
		if @off[1] == 0 then
			off = @off[0]
		else
			off = @off[0]+1
		end
		@data[off...@data.size]
	end
	
	def next(num=1)
		if @off[1] != 0
			@off[0] += 1
			@off[1] = 0
		end
		
		off = @off[0]
		@off[0] += num
		@data[off...(off + num)]
	end
	
	def nextbits(num)
		val = @data[@off[0]].ord
		left = 8 - @off[1]
		if num <= left then
			val = val >> (left - num)
			mask = (1 << num) - 1
			@off[1] += num
			if @off[1] == 8 then
				@off[0] += 1
				@off[1] = 0
			end
			
			val & mask
		else
			mask = (1 << left) - 1
			num -= left
			ret = (val & mask) << num
			@off[0] += 1
			@off[1] = 0
			
			ret | nextbits(num)
		end
	end
	
	def ubits(num)
		nextbits num
	end
	
	def sbits(num)
		val = nextbits num
		
		if val >> (num - 1) == 1 then
			val - (1 << num)
		else
			val
		end
	end
	
	def fbits(num)
		val = sbits num
		
		val / 0x10000.to_f
	end
	
	def string
		val = ''
		c = self.next 1
		while c != "\0"
			val += c
			c = self.next 1
		end
		val
	end
	
	def align
		if @off[1] != 0 then
			@off[0] += 1
			@off[1] = 0
		end
	end
end

class BStruct
	def unpack(data)
		self.class.unpack(data, self)
	end
	
	class << self
		attr :members, :endian
		
		def littleEndian?
			endian == :little
		end
		
		def endian(value=nil)
			if value == nil then
				if @endian == nil then
					:little
				else
					@endian
				end
			else
				@endian = value
			end
		end
		
		def unpack(data, obj=nil)
			if @members == nil then
				@members = []
			end
			
			obj = self.new if obj == nil
			
			for arr in @members
				dec = arr[0]
				if dec == :magic_dec then
					name = arr[2]
					check = data.next name.size
					if not name.to_s == check.to_s
						pp 'Magic failed: ' + name
						return nil
					end
				elsif dec == :custom_dec then
					name = arr[2]
					block = arr[3]
					
					val = block.call obj, data
					obj.instance_variable_set '@' + name.to_s, val
				elsif dec == :string_dec then
					name = arr[2]
					size = name.size
					if size == nil then
						val = data.string
						
						obj.instance_variable_set '@' + name.to_s, val
					else
						if size.is_a? Symbol then
							size = obj.instance_variable_get '@' + size.to_s
						end
						
						bytes = data.next size
						bytes.reverse!
						while bytes.size != 0 and bytes[0] == "\0"
							bytes = bytes[1...bytes.size]
						end
						
						obj.instance_variable_set '@' + name.to_s, bytes.reverse!
					end
				else
					dec = self.method dec
					
					name = arr[2]
					rest = arr[3...arr.size]
					if name.size? then
						size = name.size
					else
						size = -1
					end
					
					if size == -1 then
						val = dec.call obj, data, *rest
						obj.instance_variable_set '@' + name.to_s, val
					else
						if size.is_a? Symbol then
							size = obj.instance_variable_get '@' + size.to_s
						end
						
						arr = [0] * size
						obj.instance_variable_set '@' + name.to_s, arr
						for i in 0...size
							val = dec.call obj, data, *rest
							arr[i] = val
						end
					end
				end
			end
			
			obj
		end
		
		def ensureMembers
			if not @members then
				@members = []
			end
		end
		
		def add(dec, enc, names)
			ensureMembers
			
			for name in names
				iname = '@' + name.to_s
				
				class_eval %Q{
					def #{name}
						#{iname}
					end
				}
				
				@members.add [dec, enc, name]
			end
		end
		
		def addAccessor(name)
			iname = '@' + name.to_s
			
			class_eval %Q{
				def #{name}
					#{iname}
				end
			}
		end
		
		def custom(sym, &block)
			ensureMembers
			@members.add [:custom_dec, :custom_enc, sym, block]
			addAccessor sym
		end
		
		def magic(cookie)
			ensureMembers
			@members.add [:magic_dec, :magic_enc, cookie]
		end
		
		def print(*args)
			@members.add [:print_dec, :print_enc, :_, args]
		end
		def print_dec(obj, data, args)
			args = args.map {|x|
				if x.is_a? Symbol then
					obj.instance_variable_get '@' + x.to_s
				else
					x
				end
			}
			pp *args
			[nil, 0]
		end
	end
end

class String
	def uint8(off=0)
		self[off].ord
	end
	
	def uint16(off=0, endian=:little)
		bytes = self[off...(off+2)].bytes.to_a
		bytes.reverse! if endian == :little
		
		(bytes[0] << 8) | bytes[1]
	end
	
	def uint32(off=0, endian=:little)
		bytes = self[off...(off+4)].bytes.to_a
		bytes.reverse! if endian == :little
		
		(
			(bytes[0] << 24) | (bytes[1] << 16) | 
			(bytes[2] << 8) | bytes[3]
		)
	end
	
	def int32(off=0, endian=:little)
		val = uint32 off, endian
		
		if val >> 31 == 1 then
			val - 0x100000000
		else val
		end
	end
	
	def uint64(off=0, endian=:little)
		a = uint32 off, endian
		b = uint32 off+4, endian
		a, b = [b, a] if endian == :little
		
		(a << 32) | b
	end
end

class << BStruct
	def uint8(*syms)
		add :uint8_dec, :uint8_enc, syms
	end
	def uint8_dec(obj, data)
		data.next.ord
	end
	
	def uint16(*syms)
		add :uint16_dec, :uint16_enc, syms
	end
	def uint16_dec(obj, data)
		data.next(2).uint16(0, endian)
	end
	
	def uint32(*syms)
		add :uint32_dec, :uint32_enc, syms
	end
	def uint32_dec(obj, data)
		data.next(4).uint32(0, endian)
	end
	
	def uint64(*syms)
		add :uint64_dec, :uint64_enc, syms
	end
	def uint64_dec(obj, data)
		data.next(8).uint64(0, endian)
	end
	
	def string(*syms)
		add :string_dec, :string_enc, syms
	end
end

def struct(name, &block)
	eval %Q{
		class #{name} < BStruct
		end
	}
	cls = eval(name)
	cls.send :class_eval, &block
end
