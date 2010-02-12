require 'sexp_processor'

class SexpTransform
	def handle(exp, top)
		return exp if not exp.is_a? Sexp
		
		if exp.size == 0 then []
		else
			self.class.push
			
			if self.class.atoms.has_key? exp[0] then
				func = self.class.atoms[exp[0]]
				ret = func.call *(exp[1...exp.size])
				self.class.emit ret if ret != nil
			elsif self.class.drops.include? exp[0] then
				return []
			elsif self.class.ignores.include? exp[0] then
				return [exp]
			else
				puts 'Unhandled atom: ' + exp[0].to_s if not original top, exp[0]
				return [exp]
			end
			
			list = self.class.pop
			out = []
			list.each { |x|
				val = handle(x, top)
				if val.is_a? Array then
					val.each { |sub|
						subOut = []
						sub.each { |sub2|
							val = handle sub2, top
							if val.is_a? Array then subOut += val
							else subOut.add val
							end
						}
						out.add s(*subOut)
					}
				else out.add val
				end
			}
			out
		end
	end
	
	def original(exp, atom)
		return true if not exp.is_a? Sexp or exp.size == 0
		
		return false if exp[0] == atom
		for sub in exp
			return false if not original sub, atom
		end
		true
	end
	
	class << self
		def run(code)
			self.new.handle(code, code)[0]
		end
		
		def transform(atom, &block)
			@atoms = {} if @atoms == nil
			
			@atoms[atom] = block
		end
		
		def rename(old, new)
			@atoms = {} if @atoms == nil
			
			@atoms[old] = lambda { |*exp|
				emit s(new, *exp)
			}
		end
		
		def drop(*atoms)
			@drops = [] if @drops == nil
			
			@drops += atoms
		end
		
		def ignore(*atoms)
			@ignores = [] if @ignores == nil
			
			@ignores += atoms
		end
		
		def atoms
			if @atoms == nil then {}
			else @atoms
			end
		end
		
		def drops
			if @drops == nil then []
			else @drops
			end
		end
		
		def ignores
			if @ignores == nil then []
			else @ignores
			end
		end
		
		def push
			@stack = [] if @stack == nil
			@stack.add @cur
			
			@cur = []
		end
		
		def pop
			cur = @cur
			@cur = @stack.pop
			cur
		end
		
		def emit(exp)
			@cur.add exp
		end
	end
end
