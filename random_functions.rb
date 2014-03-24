module RandomFunctions


  def Exponential(mean)
    -mean * Math.log(1.0 - Random.rand())
  end

  def TruncatedExponential(mean, max)
    exp = self.Exponential(mean)
    exp < max ? exp : max
  end

  def Uniform(lower,upper)
    lower + (upper-lower)*Random.rand()
  end

  def Gaussian(mean=0, stddev=1)
    theta = 2*Math::PI*Random.rand()
    rho = Math.sqrt(-2*Math.log(1-Random.rand()))
    scale = stddev*rho
    x = mean + scale*Math.cos(theta)
    y = mean + scale*Math.sin(theta)
    return x,y
  end

  def Normal(min, max)
    #This is an approximate normal distribution
    #Map the X values
    x, y = self.Gaussian()
    #x is uniform
    #y is 
    normal = x*y
    min + (min-max)*normal
  end

end