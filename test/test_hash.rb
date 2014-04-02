require '../lib/generator.rb'
require '../lib/load_balancer.rb'

jobs = Generator.new.generate_jobs "traffic_burst", 1000
load_balancer = HashBalancer.new(jobs)
load_balancer.run
load_balancer.collect_results("Hash Test")