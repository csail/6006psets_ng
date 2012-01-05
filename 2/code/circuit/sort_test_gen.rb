#!/usr/bin/env ruby

# Generates a bitonic mergesort network.
# See http://en.wikipedia.org/wiki/Bitonic_sorter

TRUTH_TABLES = { :eq => "0 1",
                 :and2 => "0 0 0 1",
                 :or2 => "0 1 1 1" }

def make_tables(tables)
  tables.map { |name| "table #{name} #{TRUTH_TABLES[name]}\n" }.join + "\n"
end

def comparator(in1, in2, out1, out2, depth)
  in1 = "a%01d_%01d_%02d" % in1 if in1.kind_of?(Array)
  in2 = "a%01d_%01d_%02d" % in2 if in2.kind_of?(Array)
  out1 = "a%01d_%01d_%02d" % out1 if out1.kind_of?(Array)
  out2 = "a%01d_%01d_%02d" % out2 if out2.kind_of?(Array)
  
  output = <<ENDC
gate #{out1} and2_#{'%-1d' % depth} #{in1} #{in2}
gate #{out2} or0    #{in1} #{in2}
ENDC
end

def bitonic_sorter(start, n, depth)
  return if n <= 1
  output = []
  subdepth = Math.log2(n).to_i
  (0..n / 2 - 1).each do |i|
    output << comparator([depth, subdepth,     start + i],
                         [depth, subdepth,     start + n / 2 + i],
                         [depth, subdepth - 1, start + i],
                         [depth, subdepth - 1, start + n / 2 + i],
                         (start + depth) % depth)
  end
  output << bitonic_sorter(start, n / 2, depth)
  output << bitonic_sorter(start + n / 2, n / 2, depth)
  output.join
end

def merger(start, n)
  return if n <= 1
   
  output = []
  depth = Math.log2(n).to_i
  output << merger(start, n / 2)
  output << merger(start + n / 2, n / 2)
  (0..n / 2 - 1).each do |i|
    output << comparator([depth - 1, 0,         start + i], 
                         [depth - 1, 0,         start + n - 1 - i],
                         [depth,     depth - 1, start + i], 
                         [depth,     depth - 1, start + n - 1 - i],
                         (start + depth) % depth)
  end
  output << bitonic_sorter(start, n / 2, depth)
  output << bitonic_sorter(start + n / 2, n / 2, depth)
  output.join
end

# Generates a sorting network with n inputs. 
#
# Args:
#   n:: number of inputs (must be a power of 2)
def gen_circuit(n)
  unless Math.log2(n).to_i == Math.log2(n)
    raise "Number of inputs needs to be power of 2" 
  end
  output = []
  
  output << make_tables([:eq, :and2, :or2])
  
  output <<  <<ENDC
type in eq  0
type or0 or2 1
ENDC

  depth = Math.log2(n).to_i
  
  (0..depth).each { |i| output << "type and2_#{i} and2 #{1000 * 2 ** i}\n" }

  (0..n - 1).each { |i| output << "gate a0_0_#{'%02d' % i} in\n" }
  output << merger(0, n)
  
  output << "\n"
  
  (0..n - 1).each { |i| output << ("probe a%01d_0_%02d\n" % [depth, i]) }
  
  output << "\n"
  
  (0..n-1).each { |i| output << ("flip a0_0_%02d 0 0\n" % [i]) }
  (0..n-1).each { |i| output << ("flip a0_0_%02d 1 1000\n" % [i]) }
  
  (0..n-1).each do |i|
    output << ("flip a0_0_%02d %d %d\n" % [i, 1 - i % 2, 2000 + i * 1000])
  end
  (0..n-1).each do |i|
    output << ("flip a0_0_%02d %d %d\n" % [i, i % 2, 4000 + i * 1000])
  end
  
  output << "done\n"
  output.join
end

# Add Math.log2 for Ruby 1.8
unless Math.respond_to?(:log2)
  module Math
    def self.log2(n)
      log(n) / log(2)
    end
  end
end

if __FILE__ == $0
  puts gen_circuit(ARGV[0].to_i)
end
