# with an M/M/c setup, increase arrival rate 

require '../lib/generator.rb'
require '../lib/load_balancer.rb'
require 'simpleoutput'
require 'simpleplot'
require 'simplechartkick'

# Set up logging and plotting
output = SimpleOutput::SimpleOutputEngine.new
plot = SimplePlot.new("_profile")
output.addPlugin(plot)

simulations = ["traffic_exponential"]

JOB_COUNT = 500000
server_count = 5
service_rate = 200

initial_arrival_rate = 200
final_arrival_rate = 1000
arrival_rate_step = 200

(initial_arrival_rate..final_arrival_rate).step(arrival_rate_step) do |arrival_rate|
  puts arrival_rate

  # create a generator object with the specified arrival rate and service rate
  traffic = Generator.new(1.0/arrival_rate,1.0/service_rate,0,(2**31)-1,nil)

  # for each simulation type in the simulations array
  simulations.each do |name| 
    #generate a series of <JOB_COUNT> jobs using the specified generation type
    jobs = traffic.generate_jobs(name, JOB_COUNT)

    balanced_loads = Hash.new
    balanced_loads['Round Robin'] = RoundRobinBalancer.new(jobs, server_count)
    balanced_loads['Random'] = RandomBalancer.new(jobs, server_count)
    balanced_loads['Least Connected'] = LeastConnectedBalancer.new(jobs, server_count)

    balanced_loads.each do |method, trial|
      puts method
      puts trial.simulate(name)
    end
  end
  output.save();
end