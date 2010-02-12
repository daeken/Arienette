require 'swf'
require 'unify'
require 'rubyBackend'

code = Swf.load ARGV.shift
#pp code
code = Unify.run code
#pp code

out = File.new(ARGV.shift, 'w')
out.write RubyBackend.compile(code)
