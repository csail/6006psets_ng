#!/usr/bin/env ruby

require 'rubygems'
require 'active_support'

def random_pick(options, picks)
  options = options.dup
  result = []
  0.upto(picks - 1) do |i|
    pick = i + rand(options.length - i)
    options[i], options[pick] = options[pick], options[i]
    result << options[i]
  end
  result
end

def gen_test(vertical_res, horizontal_chords, min_pieces, max_pieces,
             horizontal_res, vertical_wires, min_length, max_length, seed)
  srand seed
  y0 = -(vertical_res / 2)
  y1 = vertical_res + y0
  x0 = -(horizontal_res / 2) * 10
  x1 = (horizontal_res + x0 / 10) * 10
  commands = []

  # Horizontal wires.
  y_coords = random_pick((y0..y1).to_a, horizontal_chords)
  x_ends = random_pick(((x1 + 1)..(x1 + horizontal_chords)).to_a,
                       horizontal_chords) 
  0.upto(horizontal_chords - 1) do |i|
    xs = x0 - horizontal_chords + i
    xe = x_ends[i]
    pieces = min_pieces + rand(max_pieces - min_pieces + 1)
    endpoints = [xs, xe]
    (pieces - 1).times do |p|
      gap_start = rand(horizontal_res * 10) + x0
      gap_end = gap_start + 1 + rand(5)
      endpoints << gap_start
      endpoints << gap_end
    end
    endpoints.sort!
    0.upto(pieces - 1) do |j|
      xs = endpoints[j * 2]
      xe = endpoints[j * 2 + 1]
      commands << "wire h#{i}s#{j} #{xs} #{y_coords[i]}0 #{xe} #{y_coords[i]}0"  
    end
  end
  
  # Vertical wires.
  x_coords = random_pick(((x0 / 10)..(x1 / 10)).to_a.map { |x| x * 10 },
                         vertical_wires)
  0.upto(vertical_wires - 1) do |i|
    ys = rand(vertical_res * 10 - max_length * 10) + y0 * 10
    ye = ys + min_length * 10 + rand(max_length * 10 - min_length * 10 + 1)
    commands << "wire v#{i} #{x_coords[i]} #{ys} #{x_coords[i]} #{ye}"
  end
  
  # Shuffle the commands so they're not sorted.
  commands = random_pick(commands, commands.length)

  commands.push 'done'
  commands.join "\n"
end

if __FILE__ == $0
  if ARGV.length < 8 || ARGV.length > 9
    puts <<END_USAGE
Usage: #{__FILE__} vertical_res hortizontal_chords min_pieces max_pieces
       horizontal_res vertical_wires min_length max_length [seed]
       
vertical_res: vertical resolution (precision for horizontal wires and queries)
horizontal_chords: lines on the grid
min_pieces, max_pieces: number of segments in a horizontal grid line
horizontal_res: horizontal resolution (shouldn't matter too much)
vertical_wires: number of vertical wires (queries)
min_length, max_length: the length of a vertical (query) wire
seed: random number generator seed
END_USAGE
    exit 1
  end
  
  args = ARGV.map(&:to_i)
  args << srand if args.length == 8
  puts "# Arguments: " + args.join(' ')
  puts gen_test(*args)
end
