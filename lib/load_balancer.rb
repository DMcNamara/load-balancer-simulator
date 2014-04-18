class LoadBalancer
  require 'simpleoutput'
  require 'simplechartkick'
  require 'simpleplot'
  require 'simplelog'
  require '../lib/random_functions'
  
  # accepts input array from generator and passes them to the servers based on various methods
  def initialize(jobs, server_count = 10)
    @jobs = Array.new(jobs)
    # array of server objects
    @servers = Array.new
    server_count.times{@servers.push(Server.new(10, 1))}
    @name = "Generic"
    @average_wait = 0
    @average_queue = 0
    @average_use = 0
    @average_throughput = 0
  end

  def run
    #Virtual
  end

  def simulate(uid)
    @average_wait = 0
    @average_queue = 0
    @average_use = 0
    @average_throughput = 0
    self.run
    self.collect_results(uid)
  end

  def collect_results(uid)
    output = SimpleOutput::SimpleOutputEngine.new
    html = SimpleChartkick.new("#{@name} Server Trace #{uid}.html", "#{@name} Server Trace", '../include')
    plot = SimplePlot.new("#{@name}_trace_#{uid}")
    log = SimpleCSV.new("#{@name}_trace_#{uid}")
    output.addPlugin(html)
    output.addPlugin(plot)
    output.addPlugin(log)
    @servers.each_with_index do |server,i|
      unless server.queue_length_data.size < 1 || server.wait_data.size < 1
        if i == 0
          output.setArray(server.queue_length_data, "Average Queue Length", {'xsize' => 2000, 'ysize' => 1500, 'xlabel' => 'jobs', 'ylabel' => 'queue size', 'series'=>"server #{i}"})
          output.setArray(server.wait_data, "Average Wait", {'xsize' => 2000, 'ysize' => 1500,'xlabel' => 'jobs', 'ylabel' => 'wait time', 'chart_type' => 'ColumnChart', 'series' => "server #{i}"})
        else
          output.appendArray(server.queue_length_data, "Average Queue Length", {'xsize' => 2000, 'ysize' => 1500,'xlabel' => 'jobs', 'ylabel' => 'queue size', 'series'=>"server #{i}"})
          output.appendArray(server.wait_data, "Average Wait", {'xsize' => 2000, 'ysize' => 1500,'xlabel' => 'jobs', 'ylabel' => 'wait time', 'chart_type' => 'ColumnChart', 'series' => "server #{i}"})
        end
        @average_use += server.active_time == 0 ? 0 : server.load_time/ server.active_time
        @average_throughput += server.total_jobs/server.active_time
        queue_sum = 0
        server.queue_length_data.each {|x| queue_sum += x }
        @average_queue += queue_sum/server.queue_length_data.size
        wait_sum = 0
        server.wait_data.each {|x| wait_sum += x}
        @average_wait += wait_sum/server.wait_data.size
        output.annotate("Rejected jobs: #{server.rejections}")
        output.annotate("Jobs processed: #{server.total_jobs}")
      end
      @results = {'average_throughput' => @average_throughput/@servers.size, 'average_use' => @average_use/@servers.size, 'average_queue' => @average_queue/@servers.size, 'average_wait' => @average_wait/@servers.size}
    end
    output.save()
    return @results
  end
  
end

# various Load balancing methods
class RoundRobinBalancer < LoadBalancer
  def initialize(jobs, server_count = 10)
    super
    @name ="RoundRobin"
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
  def initialize(jobs, server_count = 10)
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
  def initialize(jobs, server_count = 10)
    super
    @name = "LeastConnected"
  end
  def run
    @jobs.each do |job|
      load = @servers.first.connections(job.arrival)
      least_index = 0
      @servers.each_with_index do |server, index|
        if server.connections(job.arrival) < load 
          load = server.connections(job.arrival)
          least_index = index
        end
      end
      @servers[least_index].push_job(job)
    end
  end
end

class HashBalancer < LoadBalancer
  def initialize(jobs, server_count = 10)
    super
    @name = "Hash"
  end
  def run
    @jobs.each do |job|
      index = job.source % @servers.size
      @servers[index].push_job(job)
    end
  end
end

class Server
  attr_accessor :queue_length_data, :rejections, :wait_data, :load_time, :total_jobs, :active_time
  include RandomFunctions
  def initialize(queue_length, speed)
    @queue = [] 
    @max_queue_length = queue_length
    @rejections = 0
    @wait_data = []
    @mean_service_time = 0.001
    @queue_length_data = []
    @load_time = 0
    @total_jobs = 0
    @active_time = 0
  end

  def push_job(job)

    #Clear finished jobs
    while (@queue.size > 0) ? (@queue.first.departure < job.arrival) : false
      @queue.shift
    end
    #Log size
    @queue_length_data << @queue.size == 0 ? 0 : @queue.size - 1
    #Do we have a queue slot?
    @total_jobs += 1
    if @queue.size < @max_queue_length
      #Calculate time until job starts
      start_time = (@queue.size > 0) ? ((@queue.last.departure > job.arrival) ? @queue.last.departure : job.arrival) : job.arrival     
      #Log wait time
      @wait_data << start_time-job.arrival
      #Calculate time to process job
      service_time = Exponential(@mean_service_time)
      #Log work time
      @load_time += service_time
      #Calculate departure 
      depart_time = start_time + service_time
      #Add departure to job 
      job.departure = depart_time
      @active_time = depart_time
      #Add job to queue
      @queue << job
    else
      @rejections += 1
    end
  end

  def connections(arrival)
    while @queue.size > 0 ? @queue.first.departure < arrival : false
      @queue.shift
    end
    @queue.size
  end
end