#!/usr/bin/env ruby

require 'test/unit'

if ENV['QUEUE']
  require './full_circuit.rb'
else
  require './circuit.rb'
end  

class CircuitTest < Test::Unit::TestCase
  Dir['tests/*.in'].sort_by(&:to_i).each do |in_file|
    method_name = File.basename(in_file).split('.', 2).first
    define_method :"test_#{in_file}" do
      gold_file = in_file.sub /\.in$/, '.gold'
      gold_lines = File.readlines(gold_file).map(&:strip)
      
      sim = File.open(in_file) { |f| Simulation.from_file f }
      sim.queue :queue => (ENV['QUEUE'] || 'slow').downcase.to_sym
      sim.run
      output_lines = sim.outputs_as_lines_array
      
      assert_equal gold_lines, output_lines, 'Wrong answer!'
    end
  end
end
