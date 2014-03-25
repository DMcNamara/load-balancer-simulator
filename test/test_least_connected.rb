require '../lib/project_prototype.rb'

include Generator

jobs = generate_jobs "traffic_burst", 1000
load_balancer = LeastConnectedBalancer.new(jobs)
load_balancer.run
load_balancer.collect_results("Least Connected Test")