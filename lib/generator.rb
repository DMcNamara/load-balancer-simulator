require '../lib/random_functions.rb'

class Generator # or module
  include RandomFunctions
  Job = Struct.new(:arrival, :length, :source, :departure)
   # outputs list of [[arrival_time, job_length, source]] using various methods
   # source is an int representing IP, is [0 to int limit], randomly generated
  def initialize( min_arrival = 0, #immediately (same time)
                  max_arrival = 100, #units
                  mean_arrival = nil, #middle

                  #Length
                  min_job_length = 1, 
                  max_job_length = 30, #300Mb
                  mean_job_length = 15, 

                  min_source = 0, #Zero
                  max_source = 2**31-1, #int max
                  mean_source = nil)
    @min_arrival = min_arrival #immediately (same time)
    @max_arrival = max_arrival #units
    if(mean_arrival.nil?)
      @mean_arrival = max_arrival/2 #middle
    else
      @mean_arrival = mean_arrival
    end

    #Bytes
    @min_job_length = min_job_length #5b
    @max_job_length = max_job_length #300Mb
    @mean_job_length = mean_job_length #30b

    @min_source = min_source #Zero
    @max_source = max_source #int max
    if mean_source.nil?
      @mean_source = max_source/2 #middle
    else
      @mean_source = mean_source
    end
  end




  def generate_jobs(method, job_count = 2**15)
    

    jobs = []
    last_arrival = 0

    if(method == "traffic_burst")
      #Jobs arrive in a real way
      #Small jobs much more likely
      #Source locality modeled by normal distribution
      arrivals = burst_arrivals(job_count)
      arrivals.each do |arrival|
        jobs << Job.new(arrival, Normal(@min_job_length, @max_job_length), Normal(@min_source,@max_source),0)
      end
      return jobs
    else
      job_count.times do
        case method
        when "traffic_normal"
          #Jobs arrive in a normally distributed fashon
          #Small jobs much more likely
          #Source locality modeled by normal distribution
          jobs << Job.new(last_arrival + Normal(@min_arrival, @max_arrival), Exponential(@mean_job_length), Normal(@min_source, @max_source),0)
        when "traffic_uniform"
          #Jobs arrive randomly
          #Small jobs much more likely
          #Source locality modeled by normal distribution
          jobs << Job.new(last_arrival + Uniform(@min_arrival,@max_arrival), Exponential(@mean_job_length), Normal(@min_source, @max_source),0)
        when "traffic_exponential"
          #Rapid arrivals very likely
          #Small jobs much more likely
          #Source locality modeled by normal distribution
          jobs << Job.new(last_arrival + TruncatedExponential(@mean_arrival, @max_arrival), Exponential(@mean_job_length), Normal(@min_source, @max_source),0)
        when "source_uniform"
          #Jobs arrive in a normally distributed fashon
          #Small jobs much more likely
          #Global and equal source addresses
          jobs << Job.new(last_arrival + Normal(@min_arrival, @max_arrival), Exponential(@mean_job_length), Uniform(@min_source, @max_source),0)
        when "source_exponential"
          #Jobs arrive in a normally distributed fashon
          #Small jobs much more likely
          #Small source addresses much more likely (High locality)
          jobs << Job.new(last_arrival + Normal(@min_arrival, @max_arrival), Exponential(@mean_job_length), TruncatedExponential(@mean_source, @max_source),0)
        when "length_normal"
          #Jobs arrive in a normally distributed fashon
          #Medium length jobs are common
          #Source locality modeled by normal distribution
          jobs << Job.new(last_arrival + Normal(@min_arrival, @max_arrival), Normal(@min_job_length, @max_job_length), Normal(@min_source, @max_source),0)
        when "length_uniform"
          #Jobs arriv in a normally distributed fashon
          #Jobs of all lengths are common
          #Source locality modeled by normal distribution
          jobs << Job.new(last_arrival + Normal(@min_arrival, @max_arrival), Uniform(@min_job_length, @max_job_length), Normal(@min_source, @max_source),0)
        end
        last_arrival = jobs.last.first
      end
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