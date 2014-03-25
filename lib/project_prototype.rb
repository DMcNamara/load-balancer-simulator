require '../lib/random_functions.rb'

# queue length limits for servers?
module Generator # or module
  include RandomFunctions
   # outputs list of [[arrival_time, job_length, source]] using various methods
   # source is an int representing IP, is [0 to int limit], randomly generated
  def generate_jobs(method, job_count = 2**15)
    jobs = []
    #job_count should be a power of 2 for the B model

    #arrival times
    min_arrival = 0
    max_arrival = 10
    mean_arrival = max_arrival/2

    min_job_length = 5
    max_job_length = 300000
    mean_job_length = 30

    min_source = 0;
    max_source = 2**31-1
    mean_source = max_source/2

    last_arrival = 0

    if(method == "traffic_burst")
      arrivals = burst_arrivals(job_count, mean_job_length)
      arrivals.each do |arrival|
        jobs << [arrival, RandomFunctions::Exponential(mean_job_length), RandomFunctions::Normal(min_source,max_source)]
      end
      return jobs
    else
      job_count.times do
        case method
        when "traffic_normal"
          jobs << [last_arrival + RandomFunctions::Normal(min_arrival, max_arrival), RandomFunctions::Exponential(mean_job_length), RandomFunctions::Normal(min_source, max_source) ]
        when "traffic_uniform"
          jobs << [last_arrival + RandomFunctions::Uniform(min_arrival,max_arrival), RandomFunctions::Exponential(mean_job_length), RandomFunctions::Normal(min_source, max_source)]
        when "traffic_exponential"
          jobs << [last_arrival + RandomFunctions::TruncatedExponential(mean_arrival, max_arrival), RandomFunctions::Exponential(mean_job_length), RandomFunctions::Normal(min_source, max_source)]
        when "source_uniform"
          jobs << [last_arrival + RandomFunctions::Normal(min_arrival, max_arrival), RandomFunctions::Exponential(mean_job_length), RandomFunctions::Uniform(min_source, max_source)]
        when "source_exponential"
          jobs << [last_arrival + RandomFunctions::Normal(min_arrival, max_arrival), RandomFunctions::Exponential(mean_job_length), RandomFunctions::TruncatedExponential(mean_source, max_source)]
        when "length_normal"
          jobs << [last_arrival + RandomFunctions::Normal(min_arrival, max_arrival), RandomFunctions::Normal(min_job_length, max_job_length), RandomFunctions::Normal(min_source, max_source)]
        when "length_uniform"
          jobs << [last_arrival + RandomFunctions::Normal(min_arrival, max_arrival), RandomFunctions::Uniform(min_job_length, max_job_length), RandomFunctions::Normal(min_source, max_source)]
        end
        last_arrival = jobs.last.first
      end
    end
    jobs
  end

  def burst_arrivals(job_count, mean_job_length)
    #Use B model of burstness: http://www.pdl.cmu.edu/ftp/Workload/bmodel.pdf 
    accumulator = 0
    arrivals = []
    stack = []
    aggrigation_level = Math.log2(job_count)
    #should model real burst traffic closely
    bias = 0.795
    stack.push([0, job_count*mean_job_length])
    while(!stack.empty?)
      kv_pair = stack.pop()
      if kv_pair[0] >= aggrigation_level
        arrivals.push(accumulator += kv_pair[1])
      else
        a = [kv_pair[0]+1, kv_pair[1]*bias]
        b = [kv_pair[0]+1, kv_pair[1]*(1-bias)]
        if Random.rand < 0.5
          stack.push a
          stack.push b
        else
          stack.push b
          stack.push a
        end
      end
    end
    arrivals
  end
end

class LoadBalancer
  require 'simpleoutput'
  require 'simplechartkick'
  require 'simpleplot'
  # accepts input array from generator and passes them to the servers based on various methods
  def initialize(jobs, server_count = 10)
    @jobs = jobs
    # array of server objects
    @servers = Array.new
    server_count.times{@servers.push(Server.new(10, 1))}
    @name = "Generic"
  end

  def run
    #Virtual
  end

  def simulate(run_title)
    self.run
    self.collect_results(run_title)
  end

  def get_least_connected_server
    least_connected_server = 0
    least_load_size = @servers.first.connections
    @servers.each_with_index do |server,i|
      if server.connections < least_load_size
        least_load_size = server.connections
        least_connected_server = i
      end
    end
    return @servers[least_connected_server]
  end

  def collect_results(output_name, output=nil)
    if output == nil
      output = SimpleOutput::SimpleOutputEngine.new
      output.addPlugin(SimplePlot.new(output_name + @name))
      output.addPlugin(SimpleChartkick.new("#{output_name+@name}.html", output_name+@name, "../include"))
    end
    @servers.each_with_index do |server,i|
      output.setArray(server.queue_length_data, "Server#{i}-Queue", {'xlabel' => 'jobs', 'ylabel' => 'queue size', 'series'=>'queue size'})
      output.setArray(server.wait_data, "Server#{i}-Wait", {'xlabel' => 'jobs', 'ylabel' => 'wait time', 'chart_type' => 'ColumnChart', 'series' => 'wait time'})
      avg_use = server.load_time/server.active_time
      output.annotate("Rejected jobs: #{server.rejections}")
      output.annotate("Average Workload: #{avg_use}")
      output.annotate("Jobs processed: #{server.total_jobs}")
    end
    output.save()
  end
end

# various Load balancing methods
class RoundRobinBalancer < LoadBalancer

  def initialize(jobs)
    super
    @name = "RoundRobin"
  end
  def run
    while !@jobs.empty?
      @servers.each do |server|
        if(@jobs.size > 0)
          server.push_job(@jobs.shift)
        else
          break
        end
      end
    end
  end
end


class RandomBalancer < LoadBalancer
  def initialize(jobs)
    super
    @name = "Random"
  end
  def run
    @jobs.each do |job|
      index = Random.rand(0..@servers.size-1)
      @servers[index].push_job(job)
    end
  end
end

class LeastConnectedBalancer < LoadBalancer
  def initialize(jobs)
    super
    @name = "LeastConnected"
  end
  def run
    @jobs.each do |job|
      self.get_least_connected_server.push_job(job)
    end
  end
end

class HashBalancer < LoadBalancer
  def initialize(jobs)
    super
    @name = "Hash"
  end
  def run
    @jobs.each do |job|
      @servers[@job.source % @servers.size].push_job(job)
    end
  end
end

class Server
  attr_accessor :queue_length_data, :rejections, :wait_data, :load_time, :total_jobs, :active_time

  def initialize(queue_length, speed)
    @queue = [] 
    @max_queue_length = queue_length
    @rejections = 0
    @speed = 1
    @wait_data = []
    @queue_length_data = []
    @load_time = 0
    @total_jobs = 0
    @active_time = 0
  end

  def push_job(job)
    #Clear finished jobs
    while @queue.size > 0 ? @queue.first.last < job[0] : false
      @queue.shift
    end
    #Log size
    @queue_length_data << @queue.size == 0 ? 0 : @queue.size - 1
    #Do we have a queue slot?
    @total_jobs += 1
    if @queue.size < @max_queue_length
      #Calculate time until job starts
      start_time = @queue.size > 0 ? @queue.last[3] : job[0]
      #Log wait time
      @wait_data << start_time-job[0]
      #Calculate time to process job
      service_time = job[1]/@speed
      #Log work time
      @load_time += service_time
      #Calculate departure 
      depart_time = start_time + service_time
      #Add departure to job 
      job << depart_time
      @active_time = depart_time
      #Add job to queue
      @queue << job
    else
      @rejections += 1
    end
  end

  def connections
    @queue.size
  end
end