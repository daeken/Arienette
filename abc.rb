require 'BStruct'
require 'sexp_processor'
require 'abcInstructions'

class Buffer
	def int24
		val = self.next(2).uint16 | (self.next.uint8 << 16)
		
		if val & 0x800000 == 0 then val
		else val - 0x01000000
		end
	end
	
	def uint30
		val = 0
		off = 0
		for i in 0...5
			nval = self.next.uint8
			val |= (nval & 0x7F) << off
			off += 7
			break if nval & 0x80 == 0
		end
		val
	end
	
	def encUint32
		val = 0
		off = 0
		for i in 0...5
			nval = self.next.uint8
			val |= (nval & 0x7F) << off
			off += 7
			break if nval & 0x80 == 0
		end
		val
	end
	
	def encInt32
		val = 0
		off = 0
		for i in 0...5
			nval = self.next.uint8
			val |= (nval & 0x7F) << off
			off += 7
			break if nval & 0x80 == 0
		end
		
		if val >> (off - 1) == 1 then
			val - (1 << off)
		else val
		end
	end
end

class Abc
	def load(bytecode)
		@data = bytecode
		version = @data.next(4).uint32
		if version != 0x002E0010 then
			puts 'Incompatible ABC version'
			return nil
		end
		
		constantPoolUnpack
		@methods = (0...@data.uint30).map {|i| methodUnpack }
		@metadata = (0...@data.uint30).map {|i| metadataUnpack }
		classCount = @data.uint30
		@instances = (0...classCount).map {|i| instanceUnpack }
		(0...classCount).each {|i|
			_, cinit, traits = classUnpack
			@instances[i].add cinit
			@instances[i].add traits
		}
		@scripts = (0...@data.uint30).map {|i| scriptUnpack }
		methodBodies = (0...@data.uint30).map {|i| methodBodyUnpack }
		
		methodBodies.each do |body|
			method = @methods[body[1]]
			body.delete_at 1
			method[7] = body
		end
		
		scriptsExpr
	end
	
	def constantPoolUnpack
		@integers = [0] + (0...(@data.uint30-1)).map {|i| @data.encInt32 }
		@uintegers = [0] + (0...(@data.uint30-1)).map {|i| @data.encUint32 }
		@doubles = [0.0] + (0...(@data.uint30-1)).map {|i| @data.next 8 }
		@strings = [''] + (0...(@data.uint30-1)).map {|i| @data.next @data.uint30 }
		@namespaces = [nil] + (0...(@data.uint30-1)).map {|i|
				[@data.next.uint8, @strings[@data.uint30]]
			}
		@nsSets = [nil] + (0...(@data.uint30-1)).map {|i|
				(0...@data.uint30).map {|i| @namespaces[@data.uint30] }
			}
		@multinames = [nil] + (0...(@data.uint30-1)).map {|i|
				kind = @data.next.uint8
				case kind
				when 0x07, 0x0D # QName(A)
					[kind, @namespaces[@data.uint30], @strings[@data.uint30]]
				when 0x0F, 0x10 # RTQName(A)
					[kind, @strings[@data.uint30]]
				when 0x11, 0x12 # RTQNameL(A)
					[kind]
				when 0x09, 0x0E # Multiname(A)
					[kind, @strings[@data.uint30], @nsSets[@data.uint30]]
				when 0x1B, 0x1C # MultinameL(A)
					[kind, @nsSets[@data.uint30]]
				else
					puts 'Unknown multiname type: ' + kind.to_s(16)
				end
			}
	end
	
	def methodUnpack
		paramCount = @data.uint30
		returnType = @multinames[@data.uint30]
		paramTypes = (0...paramCount).map {|i| @multinames[@data.uint30] }
		name = @strings[@data.uint30]
		flags = @data.next.uint8
		if flags & 0x08 == 0x08 then
			options = (0...@data.uint30).map {|i| [@data.uint30, @data.next.uint8] }
		else options = nil
		end
		
		if flags & 0x80 == 0x80 then
			paramNames = (0...@data.uint30).map {|i| @strings[@data.uint30] }
		else paramNames = nil
		end
		
		s :method, name, returnType, paramTypes, flags, options, paramNames, nil
	end
	
	def metadataUnpack
		name = @strings[@data.uint30]
		items = (0...@data.uint30).map {|i| s :kvpair, @strings[@data.uint30], @strings[@data.uint30] }
		
		s :metadata, name, s(:kvpairs, *items)
	end
	
	def instanceUnpack
		name = @multinames[@data.uint30]
		superName = @multinames[@data.uint30]
		flags = @data.next.uint8
		
		if flags & 0x08 == 0x08 then
			protectedNs = @namespaces[@data.uint30]
		else protectedNs = nil
		end
		
		interfaces = (0...@data.uint30).map {|i| @multinames[@data.uint30] }
		iinit = @data.uint30
		
		s :instance, name, superName, protectedNs, interfaces, iinit, traitsUnpack
	end
	
	def classUnpack
		cinit = @data.uint30
		
		s :class, cinit, traitsUnpack
	end
	
	def scriptUnpack
		init = @data.uint30
		
		s :script, init, traitsUnpack
	end
	
	def methodBodyUnpack
		method = @data.uint30
		maxStack = @data.uint30
		localCount = @data.uint30
		initStackDepth = @data.uint30
		maxStackDepth = @data.uint30
		code = Buffer.new(@data.next @data.uint30)
		
		exceptions = (0...@data.uint30).map {|i| exceptionUnpack }
		traits = traitsUnpack
		
		code = disassemble code
		
		s :methodBody, method, maxStack, localCount, initStackDepth, maxStackDepth, code, exceptions, traits
	end
	
	def exceptionUnpack
		from = @data.uint30
		to = @data.uint30
		target = @data.uint30
		excType = @data.uint30
		varName = @strings[@data.uint30]
		
		s :exception, from, to, target, excType, varName
	end
	
	def traitsUnpack
		(0...@data.uint30).map {|i|
				name = @multinames[@data.uint30]
				kind = @data.next.uint8
				
				metadata = kind & 0x40
				kind = kind & 0xF
				case kind
				when 0, 6 then # Slot/Const
					slotId = @data.uint30
					typeName = @multinames[@data.uint30]
					vIndex = @data.uint30
					if vIndex != 0 then
						vKind = @data.next.uint8
					else vKind = nil
					end
					
					sym = if kind == 0 then :slot else :const end
					trait = s sym, slotId, typeName, vIndex, vKind
				when 4 then # Class
					slotId = @data.uint30
					classi = @data.uint30
					trait = s :class, slotId, classi
				when 5 then # Function
					slotId = @data.uint30
					function = @data.uint30
					trait = s :function, slotId, function
				when 1, 2, 3 then # Method, Getter, Setter
					dispId = @data.uint30
					method = @data.uint30
					
					if kind == 1 then sym = :method
					elsif kind == 2 then sym = :getter
					else sym = :setter
					end
					trait = s sym, dispId, method
				end
				
				if metadata == 0x40 then
					metadata = (0...@data.uint30).map {|i| @metadata[@data.uint30] }
				else metadata = nil
				end
				
				trait.add metadata
				trait
			}
	end
	
	def disassemble(code)
		insts = []
		while code.has_left?
			off = code.off[0]
			opcd = code.next.uint8
			if $insts.has_key? opcd then
				mnem, opers = $insts[opcd]
				opers = opers.map {|oper|
						case oper
						when :jumptable then (0...(code.uint30+1)).map {|i| code.int24 }
						when :multiname then @multinames[code.uint30]
						when :string then @strings[code.uint30]
						when :int24 then code.int24
						when :uint8 then code.next.uint8
						when :uint30 then code.uint30
						else
							puts 'Unknown operand type: ' + oper.to_s
							nil
						end
					}
				insts.add s(off, mnem, *opers)
			else
				puts 'Unknown opcode: ' + opcd.to_s(16)
				break
			end
		end
		
		insts
	end
	
	def scriptsExpr
		scripts = @scripts.map do |_, method, traits|
			method = methodExpr *@methods[method]
			traits = traitsExpr traits
			
			s :script, method, traits
		end
		
		s :scripts, *scripts
	end
	
	def classExpr(slot, cls)
		cls[5] = methodExpr *@methods[cls[5]]
		cls[6] = traitsExpr cls[6]
		cls[7] = methodExpr *@methods[cls[7]]
		cls[8] = traitsExpr cls[8]
		
		cls
	end
	
	def methodExpr(_, name, returnType, paramTypes, flags, options, paramNames, body)
		body = bodyExpr *body
		
		optionStart = if options != nil then paramTypes.size - options.size else nil end
		
		params = (0...paramTypes.size).map do |i|
			if paramNames != nil
				name = paramNames[i]
			else name = nil
			end
			
			if options != nil and i >= optionStart
				value = options[i - optionStart]
			else value = nil
			end
			
			s :param, name, paramTypes[i], value
		end
		
		s :method, name, returnType, flags, s(:params, *params), body
	end
	
	def bodyExpr(_, maxStack, localCount, initScope, maxScope, code, exceptions, traits)
		traits = traitsExpr traits
		
		s :body, code, exceptions, traits
	end
	
	def traitsExpr(traits)
		traits.map! do |trait|
			case trait[0]
			when :class then
				_, slot, classi = trait
				classExpr slot, @instances[classi]
			when :method then
				_, disp, method = trait
				methodExpr *@methods[method]
			when :slot then
				trait
			else
				pp trait
			end
		end
		
		s :traits, *traits
	end
	
	class << self
		def load(bytecode)
			Abc.new.load bytecode
		end
	end
end
