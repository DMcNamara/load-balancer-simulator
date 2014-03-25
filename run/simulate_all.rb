require '../project_prototype.rb'
include Generator

simulations = ["traffic_burst",
              "traffic_normal",
              "traffic_uniform",
              "traffic_exponential",
              "source_uniform",
              "source_exponential",
              "length_normal",
              "length_uniform"]
jobs = {}

simulations.each {|name| jobs[name] = Generator.generate_jobs(name)}
# various Load balancing methods
jobs.each_pair do |(name,jobs_list)|
  lbs = []
  lbs << RoundRobinBalancer.new(jobs_list)
  lbs << RandomBalancer.new(jobs_list)
  lbs << LeastConnectedBalancer.new(jobs_list)
  lbs << HashBalancer.new(jobs_list)
  lbs.each do |trial|
    trial.simulate(name)
  end
end
