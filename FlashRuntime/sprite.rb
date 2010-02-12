class Sprite
	def initialize(block)
		@frames = [[]]
		@curFrame = 0
		
		self.instance_eval &block
	end
	
	def add(&block)
		@frames[@curFrame].add block
	end
	
	def matrix(set=nil)
		@matrix = set if set != nil
		@matrix
	end
	
	def place(character, depth, matrix, ratio)
		add do
			if character == nil then
				@displayList[depth].ratio ratio if ratio != nil
				@displayList[depth].matrix matrix if matrix != nil
			else
				cls, *rest = $characters[character]
				@displayList[depth] = cls.new *rest
				@displayList[depth].ratio ratio if ratio != nil
				@displayList[depth].matrix matrix if matrix != nil
			end
		end
	end
	
	def remove(depth)
		add do
			@displayList.delete depth
		end
	end
	
	def render
		glPushMatrix
		glMultMatrix @matrix if @matrix != nil
		
		@frames.each do |frame|
			@displayList = {}
			frame.each do |elem|
				elem.call
			end
		end
		
		glPopMatrix
	end
	
	def show
		add do
			@displayList.each do |key, value|
				value.render
			end
		end
		
		@frames.add []
		@curFrame += 1
	end
end
