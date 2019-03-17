require 'benchmark'

load_time = Benchmark.bm(7) do |m|
  m.report('require') { require 'inspec' }
end
# puts load_time
