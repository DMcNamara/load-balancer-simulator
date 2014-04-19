class LoadBalancer
  require 'simpleoutput'
  require 'simplechartkick'
  require 'simpleplot'
  # accepts input array from generator and passes them to the servers based on various methods
  def initialize(jobs, server_count = 10)
    @jobs = Array.new(jobs)
    # array of server objects
    @servers = Array.new
    server_count.times{@servers.push(Server.new(500000, 1))}
    @name = "Generic"
  end

  def run
    #Virtual
  end

  def simulate(run_title)
    self.run
    self.collect_results(run_title)
  end

  def collect_results(output_name, output=nil)
    if output == nil
      output = SimpleOutput::SimpleOutputEngine.new
      output.addPlugin(SimplePlot.new(output_name + @name))
      output.addPlugin(SimpleChartkick.new("#{output_name+@name}.html", output_name+@name, "../include"))
    end
    results = {'average_throughput' => 0,
                'average_use' => 0,
                'average_queue' => 0,
                'average_wait' => 0
              }
    @servers.each_with_index do |server,i|
      
      unless server.queue_length_data.size < 1 || server.wait_data.size < 1
        if i == 0
          output.setArray(server.queue_length_data, "Queue", {'xsize' => 2000, 'ysize' => 1500, 'xlabel' => 'jobs', 'ylabel' => 'queue size', 'series'=>"server #{i}"})
          output.setArray(server.wait_data, "Wait", {'xsize' => 2000, 'ysize' => 1500,'xlabel' => 'jobs', 'ylabel' => 'wait time', 'chart_type' => 'ColumnChart', 'series' => "server #{i}"})
        else
          output.appendArray(server.queue_length_data, "Queue", {'xsize' => 2000, 'ysize' => 1500,'xlabel' => 'jobs', 'ylabel' => 'queue size', 'series'=>"server #{i}"})
          output.appendArray(server.wait_data, "Wait", {'xsize' => 2000, 'ysize' => 1500,'xlabel' => 'jobs', 'ylabel' => 'wait time', 'chart_type' => 'ColumnChart', 'series' => "server #{i}"})
        end
        results['average_use'] += server.active_time == 0 ? 0 : server.load_time/ server.active_time
        results['average_throughput'] += server.active_time == 0 ? 0 : server.total_jobs/server.active_time
        avg_queue = 0
        server.queue_length_data.each {|len| avg_queue += len}
        avg_wait = 0
        server.wait_data.each {|wait| avg_wait += wait}
        results['average_queue'] += avg_queue / server.queue_length_data.size
        results['average_wait'] += avg_wait / server.wait_data.size
        output.annotate("Rejected jobs: #{server.rejections}")
        output.annotate("Jobs processed: #{server.total_jobs}")
      end
    end
    results['average_use'] = results['average_use']/@servers.size
    results['average_throughput'] = results['average_throughput']/@servers.size
    results['average_queue'] = results['average_queue']/@servers.size
    results['average_wait'] = results['average_wait']/@servers.size
    
    #output.save()
    results
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
          @servers.each {|serv| serv.sample(@jobs.first.arrival)}
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
      @servers.each {|serv| serv.sample(job.arrival)}
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
      load = 11
      least_index = -1
      @servers.each_with_index do |server, index|
        if server.connections(job.arrival) < load 
          load = server.connections(job.arrival)
          least_index = index
        end
      end
      @servers.each {|serv| serv.sample(job.arrival)}
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
      @servers.each {|serv| serv.sample(job.arrival)}
      @servers[index].push_job(job)
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

  def sample(arrival)
    while (@queue.size > 0) ? (@queue.first.departure < arrival) : false
      @queue.shift
    end
    @queue_length_data << @queue.size == 0 ? 0 : @queue.size - 1
    start_time = (@queue.size > 0) ? ((@queue.last.departure > arrival) ? @queue.last.departure : arrival) : arrival     
      #Log wait time
    
  end

  def push_job(job)
    #Clear finished jobs
    #while (@queue.size > 0) ? (@queue.first.departure < job.arrival) : false
    #  @queue.shift
    #end
    #Do we have a queue slot?
    @total_jobs += 1
    if @queue.size < @max_queue_length
      #Calculate time until job starts
      start_time = (@queue.size > 0) ? ((@queue.last.departure > job.arrival) ? @queue.last.departure : job.arrival) : job.arrival     
      @wait_data << start_time-job.arrival
      #Calculate time to process job
      service_time = job.length/@speed
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