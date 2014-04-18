require '../lib/generator.rb'
require 'rubygems'
require 'simpleoutput'
require 'simplechartkick'
require 'simpleplot'

generator = Generator.new(1,30)

jobs = generator.generate_jobs
output = SimpleOutput::SimpleOutputEngine.new
html = SimpleChartkick.new("GeneratorTest.html", "Generator test", '../include')
plot = SimplePlot.new("_test")
output.addPlugin(html)
output.addPlugin(plot)
arrival_data = []
length_data = []
source_data = []
arrival_intervals = [0]
jobs.each_with_index do |value, index|
  arrival_data << [index, value.arrival]
  arrival_intervals << value.arrival - arrival_intervals.last
  length_data << [index, value.length]
  source_data << [index, value.source]
end 
output.setPoints(arrival_data, "Arrivals", {'xlabel' => 'count', 'ylabel' => 'time'})
output.setArray(arrival_intervals, "Intervals of Arrivals", {'xlabel' => 'arrival #', 'ylabel' => 'interval'})
output.setPoints(length_data, "Job Length", {'xlabel' => 'job #', 'ylabel' => 'time'})
output.setPoints(source_data, "Source", {'xlabel' => 'count', 'ylabel' => 'ip'})
output.save()