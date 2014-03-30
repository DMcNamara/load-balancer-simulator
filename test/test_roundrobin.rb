require '../lib/project_prototype.rb'

include Generator

jobs = generate_jobs "traffic_burst", 1000
load_balancer = RoundRobinBalancer.new(jobs)
load_balancer.run
load_balancer.collect_results("Round Robin Test")