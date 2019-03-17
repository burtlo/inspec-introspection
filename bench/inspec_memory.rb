require 'memory_profiler'
# require 'pry'

report = MemoryProfiler.report do 
  require 'inspec'
end

# binding.pry
report.pretty_print(detailed_report: true, allocated_strings: 0, retained_strings: 0)
