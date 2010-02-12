require 'opengl'
require 'sdl'
include Gl, Glu
require 'pp'

require 'FlashRuntime/util'
require 'FlashRuntime/sprite'
require 'FlashRuntime/draw'
require 'FlashRuntime/fill'
require 'FlashRuntime/shapes'

$polygonMode = GL_FILL

class Movie < Sprite
	def initialize(frameSize, frameRate, &block)
		frameRate = frameRate / 0x100.to_f
		
		$characters = {}
		
		super block
		
		SDL.init SDL::INIT_VIDEO
		SDL.setGLAttr SDL::GL_DOUBLEBUFFER, 1
		SDL.setVideoMode (frameSize[1]-frameSize[0])/20, (frameSize[3]-frameSize[2])/20, 32, SDL::OPENGL # Twips are /20
		
		glMatrixMode GL_PROJECTION
		glLoadIdentity
		gluOrtho2D frameSize[0], frameSize[1], frameSize[3], frameSize[2]
		glMatrixMode GL_MODELVIEW
		glLoadIdentity
		#glTranslatef (frameSize[1]-frameSize[0])/2, (frameSize[3]-frameSize[2])/2, 0
		
		glDisable GL_DEPTH_TEST
		glPolygonMode GL_FRONT_AND_BACK, $polygonMode
		glHint GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST
		glEnable GL_LINE_SMOOTH
		glEnable GL_POLYGON_SMOOTH
		glEnable GL_BLEND
		glBlendFunc GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA
		glDisable GL_CULL_FACE
		glHint GL_LINE_SMOOTH_HINT, GL_NICEST
		glHint GL_POLYGON_SMOOTH_HINT, GL_NICEST
		
		frameTime = 1000.0 / frameRate
		
		offset = 0
		while true
			@displayList = {}
			@frames.each do |frame|
			  while event = SDL::Event.poll
			    case event
			    when SDL::Event::Quit
			      exit
			    end
			  end
			  
				start = SDL.getTicks
				frame.each do |elem|
					elem.call
				end
				diff = SDL.getTicks - start
				SDL.delay frameTime - diff - offset if diff < frameTime and offset < diff
				offset += SDL.getTicks - start - frameTime
			end
		end
	end
	
	def backgroundColor(r, g, b)
		add do
			glClearColor color(r), color(g), color(b), 1.0
		end
	end
	
	def morphShape(character, startBounds, endBounds, fillStyles, startEdges, endEdges)
		$characters[character] = [MorphShape, startBounds, endBounds, fillStyles, startEdges, endEdges]
	end
	
	def shape(character, bounds, fillStyles, edges)
		$characters[character] = [Shape, bounds, fillStyles, edges]
	end
	
	def show
		add do
			@displayList.each do |key, value|
				value.render
			end
			swap
		end
		
		@frames.add []
		@curFrame += 1
	end
	
	def sprite(character, &block)
		$characters[character] = [Sprite, block]
	end
	
	def swap
		SDL.GLSwapBuffers
		glClear GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT
	end
end

def movie(*args, &block)
	Movie.new *args, &block
end
