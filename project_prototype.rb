# queue length limits for servers?

class Generator # or module
   # outputs list of [[arrival_time, job_length, source]] using various methods
   # source is an int representing IP, is [0 to int limit], randomly generated
  def initialize(method)

  end
 
end

class LoadBalancer
  # accepts input array from generator and passes them to the servers based on various methods
  def initalize(jobs)
    @jobs = jobs
    # array of server objects
    @servers = Array.new  
  end

  def get_least_connected_server
    least_connected_server = nil
    least_load_size = 99999999999999999999999999
    @servers.each_with_index do |i, server|
      if server.queue.size < least_load_size
        least_load_size = server.queue.size
        least_connected_server = i
      end
    end
    return @servers[least_connected_server]
  end
end

# various Load balancing methods
class RoundRobinBalancer < LoadBalancer
  while ~@jobs.empty?
    @servers.each do |server|
      server.push_job(@jobs.pop)
    end
  end
end


class RandomBalancer < LoadBalancer
  @jobs.each do |job|
    @servers[Random[0..@servers.size-1]].push_job(job)
  end
end

class LeastConnectedBalancer < LoadBalancer
  @jobs.each do |job|
    self.get_least_loaded_server.push_job(job)
  end
end

class HashBalancer < LoadBalancer
  @jobs.each do |job|
    @servers[@job.source % @servers.size].push_job(job)
  end
end

class Server
  attr_accessor :queue
  @queue_length
  def initalize(queue_length)
    @queue = Array.new  
    @queue_length = -1
  end

end