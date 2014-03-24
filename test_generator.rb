require './project_prototype.rb'
require './simplehtml.rb'
include Generator
jobs = generate_jobs "traffic_burst"
html = SimpleHTML.new("GeneratorTest.html", "Generator test", true)
arrival_data = []
length_data = []
source_data = []
jobs.each_with_index do |value, index|
  arrival_data << [index, value[0]]
  length_data << [index, value[1]]
  source_data << [index, value[2]]
end 
html.writediv("Job Arrival Times")
html.linechart(arrival_data)
html.writediv("Job Lengths")
html.columnchart(length_data)
html.writediv("Source Addr")
html.barchart(source_data)
html.save()