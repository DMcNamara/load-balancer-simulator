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

names = ["RoundRobin", "Random", "LeastConnected", "Hash"]

results = {}
service_rate = 0.125 #Units per second
start_arrival_rate = 0.1 #Arrivals per second
max_arrival_rate = 1
arrival_rate_step  = 0.1
arrival_rate = 0.1
x_vector = []
while arrival_rate < max_arrival_rate
  x_vector << arrival_rate
  arrival_rate += arrival_rate_step
end
result_plot = SimpleOutput::SimpleOutputEngine.new
html = SimpleChartkick.new("SimluationResults.html", "Simluation Results", '../include')
plot = SimplePlot.new("_result")
csv = SimpleCSV.new("result_")
result_plot.addPlugin(html)
result_plot.addPlugin(plot)
result_plot.addPlugin(csv)
while server_count < server_end
  arrival_rate = start_arrival_rate
  names.each do |name|
    results[name] = []
  end
  while arrival_rate < max_arrival_rate

    traffic = Generator.new(1.0/arrival_rate,1.0/service_rate,0,(2**31)-1,nil)
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
    output.setArray(arrival_data.clone, "S#{server_count}L#{arrival_rate}_Arrivals", {'xsize' => 1000, 'ysize' => 700,'histogram' => true, 'bincount' => 25})
    output.setArray(length_data.clone, "S#{server_count}L#{arrival_rate}_Lengths", {'xsize' => 1000, 'ysize' => 700,'xlabel' => 'length', 'ylabel' => 'count', 'histogram' => true, 'bincount' => 25})
    output.setArray(source_data.clone, "S#{server_count}L#{arrival_rate}_Src", {'xsize' => 1000, 'ysize' => 700,'xlabel' => 'source', 'ylabel' => 'count'})
    lbs = []
    lbs << RoundRobinBalancer.new(jobs, server_count)
    lbs << RandomBalancer.new(jobs, server_count)
    lbs << LeastConnectedBalancer.new(jobs, server_count)
    lbs << HashBalancer.new(jobs, server_count)
    
    lbs.each_with_index do |trial,i|
      results[names[i]] << trial.simulate(names[i])
    end
    arrival_rate += arrival_rate_step
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

    result_plot.appendXY(x_vector, use, "#{name}: Average Use Vs Load", {'xmin' => 0.1, 'xmax' => 1, 'xsize' => 2000, 'ysize' => 1400,'series' => "#{server_count} Servers"})
    result_plot.appendXY(x_vector, throughput, "#{name}: Average Throughput Vs Load", {'xmin' => 0.1, 'xmax' => 1,'xsize' => 2000, 'ysize' => 1400,'series' => "#{server_count} Servers"})
    result_plot.appendXY(x_vector, wait, "#{name}: Average Wait Vs Load", {'xmin' => 0.1, 'xmax' => 1,'xsize' => 2000, 'ysize' => 1400,'series' => "#{server_count} Servers"})
    result_plot.appendXY(x_vector, queue, "#{name}: Average Queue Size Vs Load", {'xmin' => 0.1, 'xmax' => 1,'xsize' => 2000, 'ysize' => 1400,'series' => "#{server_count} Servers"})
  end
  server_count += 1
end
result_plot.save()
output.save()