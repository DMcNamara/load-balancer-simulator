require '../lib/random_functions.rb'

class Generator # or module
  include RandomFunctions
  Job = Struct.new(:arrival,  :source, :departure)
   # outputs list of [[arrival_time, job_length, source]] using various methods
   # source is an int representing IP, is [0 to int limit], randomly generated
  def initialize( 
                  mean_arrival = 1.0/9000.0, #m
                  mean_job_length = 1000
                  min_source = 0, #Zero
                  max_source = 2**31-1, #int max
                  mean_source = nil)
    
    @mean_arrival = mean_arrival
    @mean_job_length = mean_job_length
    @min_source = min_source #Zero
    @max_source = max_source #int max
    if mean_source.nil?
      @mean_source = max_source/2 #middle
    else
      @mean_source = mean_source
    end
  end

  def generate_jobs(job_count = 2**15)

    jobs = []
    last_arrival = 0
    
    arrivals = burst_arrivals(job_count)
    arrivals.each do |arrival|
      jobs << Job.new(arrival, Normal(@min_source,@max_source),0)
    end
    jobs
  end

  def burst_arrivals(job_count)
    #Use B model of burstness: http://www.pdl.cmu.edu/ftp/Workload/bmodel.pdf 
    accumulator = 0
    arrivals = []
    stack = []
    aggrigation_level = Math.log2(job_count)
    #should model real burst traffic closely
    bias = 0.795
    stack.push([0, job_count*@mean_job_length])
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