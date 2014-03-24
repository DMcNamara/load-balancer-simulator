simulations = ["traffic_burst",
              "traffic_normal",
              "traffic_uniform",
              "traffic_exponential",
              "source_uniform",
              "source_exponential",
              "length_normal",
              "length_uniform"]
jobs = {}
simulations.each {|name| jobs[name] = Generator::generate_jobs(name)}
# various Load balancing methods
  jobs.each_pair do |(name,jobs)|
    lbs = []
    lbs << RoundRobinBalancer.new jobs
    lbs << RandomBalancer.new jobs
    lbs << LeastConnectedBalancer.new jobs
    lbs << HashBalancer.new jobs
    lbs.each do |trial|
      trial.simulate(name)
    end
  end
end