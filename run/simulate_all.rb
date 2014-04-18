require '../lib/generator.rb'
require '../lib/load_balancer.rb'
require 'simpleoutput'
require 'simpleplot'
require 'simplechartkick'
require 'simplecsv'


simulations = ["traffic_burst"]

job_count = 5000
server_count = 1
server_end = 15

output = SimpleOutput::SimpleOutputEngine.new
html = SimpleChartkick.new("TrafficProfiles.html", "Traffic", '../include')
plot = SimplePlot.new("_profile")
output.addPlugin(html)
output.addPlugin(plot)
max_load_level = 40

names = ["RoundRobin", "Random", "LeastConnected", "Hash"]

results = {}
service_rate = 0.125
arrival_rate 
x_vector = []
while load_level < max_load_level
  x_vector << load_level
  load_level += load_level_step
end
result_plot = SimpleOutput::SimpleOutputEngine.new
html = SimpleChartkick.new("SimluationResults.html", "Simluation Results", '../include')
plot = SimplePlot.new("_result")
csv = SimpleCSV.new("result_")
result_plot.addPlugin(html)
result_plot.addPlugin(plot)
result_plot.addPlugin(csv)
while server_count < server_end
  load_level = start_load_level
  names.each do |name|
    results[name] = []
  end
  while load_level < max_load_level

    traffic = Generator.new(1.0/arrival_rate,1.0/service_rate,1,30,12,0,(2**31)-1,nil)
    jobs = traffic.generate_jobs("traffic_burst", job_count)
    arrival_data = []
    length_data = []
    source_data = []
    last = 0;
    jobs.each do |job|
      arrival_data << job.arrival - last
      length_data << job.length
      source_data << job.source 
      last = job.arrival
    end
    output.setArray(arrival_data.clone, "S#{server_count}L#{load_level}_Arrivals", {'xsize' => 1000, 'ysize' => 700,'histogram' => true, 'bincount' => 25})
    output.setArray(length_data.clone, "S#{server_count}L#{load_level}_Lengths", {'xsize' => 1000, 'ysize' => 700,'xlabel' => 'length', 'ylabel' => 'count', 'histogram' => true, 'bincount' => 25})
    output.setArray(source_data.clone, "S#{server_count}L#{load_level}_Src", {'xsize' => 1000, 'ysize' => 700,'xlabel' => 'source', 'ylabel' => 'count'})
    lbs = []
    lbs << RoundRobinBalancer.new(jobs, server_count)
    lbs << RandomBalancer.new(jobs, server_count)
    lbs << LeastConnectedBalancer.new(jobs, server_count)
    lbs << HashBalancer.new(jobs, server_count)
    
    lbs.each_with_index do |trial,i|
      results[names[i]] << trial.simulate(names[i])
    end
    load_level += load_level_step
  end
  names.each do |name|
    use = []
    throughput = []
    wait = []
    queue = []
    puts name
    puts results[name]
    results[name].each do |averages|
      use << averages['average_use']
      throughput << averages['average_throughput']
      wait << averages['average_wait']
      queue << averages['average_queue']
    end
    puts use
    result_plot.appendXY(x_vector, use, "#{name}: Average Use Vs Load", {'series' => "#{server_count} Servers"})
    result_plot.appendXY(x_vector, throughput, "#{name}: Average Throughput Vs Load", {'series' => "#{server_count} Servers"})
    result_plot.appendXY(x_vector, wait, "#{name}: Average Wait Vs Load", {'series' => "#{server_count} Servers"})
    result_plot.appendXY(x_vector, queue, "#{name}: Average Queue Size Vs Load", {'series' => "#{server_count} Servers"})
  end
  server_count += 1
end
result_plot.save()
output.save()