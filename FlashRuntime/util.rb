class Array
	def add(val)
		self[self.count] = val
	end
end

def m(amt, a, b)
	amt = amt / 65536.0 if amt.is_a? Fixnum
	a + ((b - a) * amt)
end

def color v
	v / 255.0
end
