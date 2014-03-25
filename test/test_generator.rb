require '../lib/project_prototype.rb'
require 'rubygems'
require 'simpleoutput'
require 'simplechartkick'
require 'simpleplot'

include Generator

jobs = generate_jobs "traffic_burst"
output = SimpleOutput::SimpleOutputEngine.new
html = SimpleChartkick.new("GeneratorTest.html", "Generator test", '../include')
plot = SimplePlot.new("_test")
output.addPlugin(html)
output.addPlugin(plot)
arrival_data = []
length_data = []
source_data = []
jobs.each_with_index do |value, index|
  arrival_data << [index, value[0]]
  length_data << [index, value[1]]
  source_data << [index, value[2]]
end 
output.setPoints(arrival_data, "Arrivals")
output.setPoints(length_data, "Job Length")
output.setPoints(source_data, "Source")
output.save()