require '../lib/generator.rb'
require '../lib/load_balancer.rb'
require 'simpleoutput'
require 'simpleplot'
require 'simplechartkick'
require 'simplelog'
require 'simplecsv'


job_count = 5000


arrival_interval_start = 10000.0
arrival_interval_end = 20000.0
arrival_interval_step = (arrival_interval_end - arrival_interval_start)/10.0


server_count = 5
server_count_end = 5


result_plotter = SimpleOutput::SimpleOutputEngine.new
html = SimpleChartkick.new("SimulationResults.html", "Simulation Results", '../include')
plot = SimplePlot.new("_Plot")
csv = SimpleCSV.new("Data_")
result_plotter.addPlugin(html)
result_plotter.addPlugin(plot)
result_plotter.addPlugin(csv)
names = ['RoundRobin', 'Random', 'LeastConnected', 'Hash']
profile_plot = SimpleOutput::SimpleOutputEngine.new
plot = SimplePlot.new("_Jobs")
profile_plot.addPlugin(plot)
results = {}
x = 0
y = 1
until server_count > server_count_end 
  arrival_interval = arrival_interval_start
  puts "Server Count: #{server_count}"
  results[server_count] = [[],[]]
  until arrival_interval > arrival_interval_end
    results[server_count][x] << arrival_interval
    jobs = Generator.new(1.0/arrival_interval).generate_jobs(job_count)
    arrival_data = []
    source_data = []
    last = 0;
    jobs.each do |job|
      arrival_data << job.arrival - last
      source_data << job.source 
      last = arrival_data.last
    end
    profile_plot.setArray(arrival_data, "Arrival Profile", {'series_name' => "S#{server_count}_AI#{arrival_interval}", 'histogram' => true})
    
    lbs = []
    lbs << RoundRobinBalancer.new(jobs, server_count)
    lbs << RandomBalancer.new(jobs, server_count)
    lbs << LeastConnectedBalancer.new(jobs, server_count)
    lbs << HashBalancer.new(jobs, server_count)
    
    
    results[server_count][y] = []
    lbs.each_with_index do |trial,i|
      results[server_count][y] << trial.simulate("#{server_count}-#{arrival_interval}")
    end
    arrival_interval += arrival_interval_step
  end
  server_count += 1
end
profile_plot.save()
#NOW PLOT!
results.each_with_index do |pair, index|
  throughput_sum = Array.new 4
  use_sum = Array.new 4
  wait_sum = Array.new 4
  queue_sum = Array.new 4
  pair[y].each_with_index do |results, i|
    pair[y][i]['average_throughput'].each {|x| throughput_sum[i] += x}
    result_plotter.appendXY(pair[x], pair[y][i]['average_throughput'], "Average Throughput (#{index} Servers)", {'series_name' => "#{names[i]}", 'xlabel' => 'Arrival Rate', 'ylabel' => 'Throughput'})
    pair[y][i]['average_use'].each {|x| use_sum[i] += x}
    result_plotter.appendXY(pair[x], pair[y][i]['average_use'], "Average Utilization (#{index} Servers)", {'series_name' => "#{names[i]}",'xlabel' => 'Arrival Rate', 'ylabel' => 'Utilization'})
    pair[y][i]['average_wait'].each {|x| wait_sum[i] += x}
    result_plotter.appendXY(pair[x], pair[y][i]['average_wait'], "Average Wait Time (#{index} Servers)", {'series_name' => "#{names[i]}",'xlabel' => 'Arrival Rate', 'ylabel' => 'Wait'})
    pair[y][i]['average_queue'].each {|x| queue_sum[i] += x}
    result_plotter.appendXY(pair[x], pair[y][i]['average_queue'], "Average Queue Length (#{index} Servers)", {'series_name' => "#{names[i]}",'xlabel' => 'Arrival Rate', 'ylabel' => 'Queue Length'})
  end
end
result_plotter.save()