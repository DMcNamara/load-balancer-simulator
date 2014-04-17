require '../lib/generator.rb'
require 'rubygems'
require 'simpleoutput'
require 'simplechartkick'
require 'simpleplot'

generator = Generator.new

jobs = generator.generate_jobs
output = SimpleOutput::SimpleOutputEngine.new
html = SimpleChartkick.new("GeneratorTest.html", "Generator test", '../include')
plot = SimplePlot.new("_test")
output.addPlugin(html)
output.addPlugin(plot)
arrival_data = []
length_data = []
source_data = []
jobs.each_with_index do |value, index|
  arrival_data << [index, value.arrival]
  length_data << [index, value.length]
  source_data << [index, value.source]
end 
output.setPoints(arrival_data, "Arrivals", {'xlabel' => 'count', 'ylabel' => 'time'})
output.setPoints(length_data, "Job Length", {'xlabel' => 'job #', 'ylabel' => 'time'})
output.setPoints(source_data, "Source", {'xlabel' => 'count', 'ylabel' => 'ip'})
output.save()