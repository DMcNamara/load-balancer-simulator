
require '../lib/random_functions.rb'

require 'simpleoutput'
require 'simplechartkick'
require 'simpleplot'
require 'simplelog'

include RandomFunctions

output = SimpleOutput::SimpleOutputEngine.new

html = SimpleChartkick.new("GeneratorTest.html", "Generator test", '../include')
plot = SimplePlot.new("_test")
logger = SimpleLog.new("random_test")


output.addPlugin(html)
output.addPlugin(plot)
output.addPlugin(logger)

run = 10000
exp = []
run.times { exp << RandomFunctions.Exponential(30)}
output.setArray(exp, "Exponential(30)", {"histogram" => true})
exp = []
run.times { exp << RandomFunctions.TruncatedExponential(30, 60)}
output.setArray(exp, "Trunc Exp(30,60)", {"histogram" => true, 'ymin' => 0, 'ymax' => 60})

exp = []
run.times { exp <<  RandomFunctions.Uniform(0,5)}
output.setArray(exp, "Uniform", {"histogram" => true, 'ymin' => 0, 'ymax' => 5 })

gaussX = []
gaussY = []
puts "Gaussian"
run.times do 
	x,y = RandomFunctions.Gaussian(0, 1)
	gaussX << x
	gaussY << y
end
output.setXY(gaussX, gaussY, "Gauss")
output.setArray(gaussX, "GaussX", {"histogram" => true})
output.setArray(gaussY, "GaussY", {"histogram" => true})

puts "Normal"
normal = []
run.times {normal << RandomFunctions.Normal(0, 10)}
output.setArray(normal, "Normal", {"histogram" => true, 'ymin' => 0, 'ymax' => 11})
output.save()