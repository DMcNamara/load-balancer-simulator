require '../lib/generator.rb'
require '../lib/load_balancer.rb'


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

simulations.each do |name| 
  jobs = Generator.new.generate_jobs(name, job_count)
  lbs = []
  lbs << RoundRobinBalancer.new(jobs, server_count)
  lbs << RandomBalancer.new(jobs, server_count)
  lbs << LeastConnectedBalancer.new(jobs, server_count)
  lbs << HashBalancer.new(jobs, server_count)
  lbs.each do |trial|
    trial.simulate(name)
  end
end
