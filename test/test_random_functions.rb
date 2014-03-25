require '../lib/random_functions.rb'
include RandomFunctions

puts "Exponentials(30)"
10.times {puts RandomFunctions.Exponential(30)}
puts "Truncated Exp(30,60)"
10.times {puts RandomFunctions.TruncatedExponential(30, 60)}
puts "Uniform(0,5)"
10.times {puts RandomFunctions.Uniform(0,5)}
puts "Gaussian"
10.times {puts RandomFunctions.Gaussian(0, 1)}
puts "Normal"
10.times {puts RandomFunctions.Normal(0, 10)}