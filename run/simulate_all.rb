require '../lib/generator.rb'
require '../lib/load_balancer.rb'
require 'simpleoutput'
require 'simpleplot'
require 'simplechartkick'


simulations = ["traffic_burst",
              "traffic_normal",
              "traffic_uniform",
              "traffic_exponential",
              "source_uniform",
              "source_exponential",
              "length_normal",
              "length_uniform"]

job_count = 5000
server_count = 5
traffic = Generator.new(0,20,5,1,30,15,0,(2**31)-1,nil)
output = SimpleOutput::SimpleOutputEngine.new
html = SimpleChartkick.new("TrafficProfiles.html", "Traffic", '../include')
plot = SimplePlot.new("_profile")
output.addPlugin(html)
output.addPlugin(plot)

simulations.each do |name| 

  jobs = traffic.generate_jobs(name, job_count)
  arrival_data = []
  length_data = []
  source_data = []
  last = 0;
  jobs.each do |job|
    arrival_data << job.arrival - last
    length_data << job.length
    source_data << job.source 
    last = arrival_data.last
  end
  output.setArray(arrival_data.clone, "#{name}_Arrivals", {'xsize' => 1000, 'ysize' => 700, 'histogram' => true, 'bincount' => 20})
  output.setArray(length_data.clone, "#{name}_Lengths", {'xsize' => 1000, 'ysize' => 700,'xlabel' => 'length', 'ylabel' => 'count', 'histogram' => true, 'bincount' => 100})
  output.setArray(source_data.clone, "#{name}_Src", {'xsize' => 1000, 'ysize' => 700,'xlabel' => 'source', 'ylabel' => 'count'})
  lbs = []
  lbs << RoundRobinBalancer.new(jobs, server_count)
  lbs << RandomBalancer.new(jobs, server_count)
  lbs << LeastConnectedBalancer.new(jobs, server_count)
  lbs << HashBalancer.new(jobs, server_count)
  lbs.each do |trial|
    trial.simulate(name)
  end
end
output.save();