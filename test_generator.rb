require './project_prototype.rb'
require 'rubygems'
require 'simpleoutput'
require 'simplechartkick'

include Generator

jobs = generate_jobs "traffic_burst"
html = SimpleChartkick.new("GeneratorTest.html", "Generator test", './')
arrival_data = []
length_data = []
source_data = []
jobs.each_with_index do |value, index|
  arrival_data << [index, value[0]]
  length_data << [index, value[1]]
  source_data << [index, value[2]]
end 
html.setPoints(arrival_data, "Arrivals")
html.setPoints(length_data, "Job Length")
html.setPoints(source_data, "Source")
html.save()