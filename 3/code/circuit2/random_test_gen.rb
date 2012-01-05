#!/usr/bin/env ruby

def gen_test(wire_count, resolution)
  commands = (1..wire_count).map do |i|
    l1 = rand(resolution) - resolution / 2
    l2 = rand(resolution) - resolution / 2
    l3 = rand(resolution) - resolution / 2
    
    l1, l2 = l2, l1 if l1 > l2
    l2 = l1 + 1 if l1 == l2
    if rand(2) == 0
      # Horizontal
      "wire h#{i} #{l1} #{l3} #{l2} #{l3}"
    else
      "wire v#{i} #{l3} #{l1} #{l3} #{l2}"
    end
  end
  commands.push 'done'
  commands.join "\n"
end

if __FILE__ == $0
  if ARGV.length != 2
    puts <<END_USAGE
Usage: #{__FILE__} wire_count resolution
END_USAGE
    exit 1
  end
  puts gen_test(ARGV[0].to_i, ARGV[1].to_i)
end
