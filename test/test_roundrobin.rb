require '../lib/generator.rb'
require '../lib/load_balancer.rb'
jobs = Generator.new.generate_jobs 1000
load_balancer = RoundRobinBalancer.new(jobs)
load_balancer.run
load_balancer.collect_results("Round Robin Test")