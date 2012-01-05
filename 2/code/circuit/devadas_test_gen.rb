#!/usr/bin/env ruby

# Generates a circuit with an exponential number of transitions vs. gate count.
# Google for the PDF of "Event Suppression: Improving the Efficiency of Timing Simulation for Synchronous Digital Circuits"

TRUTH_TABLES = { :eq => "0 1",
                 :and2 => "0 0 0 1",
                 :or2 => "0 1 1 1",
                 :xor2 => "0 1 1 0" }

def make_tables(tables)
  tables.map { |name| "table #{name} #{TRUTH_TABLES[name]}\n" }.join + "\n"
end

# Generates the circuit input based on Srini's paper.
#
# Args:
#   stages:: number of stages in the circuit.
def gen_circuit(stages)
  output = []
  
  output << make_tables([:eq, :and2, :xor2])
  
  output << <<ENDC
type in eq 0
type and0 and2 1
type xor0 xor2 1
ENDC
  (1..stages).each { |i| output << "type and#{i} and2 #{1000 * 2**i}\n" }
  
  output << "\ngate z0 in\n"
  (1..stages).each do |i|
    output << <<ENDC
gate a#{i} in
gate b#{i} in
gate x#{i} and#{i} a#{i} z#{i - 1}
gate y#{i} and0 b#{i} z#{i - 1}
gate z#{i} xor0 x#{i} y#{i}
ENDC
  end
  
  output << <<ENDC
  
probe z#{stages}
  
flip z0 0 0
ENDC

  (1..stages).each do |i|
    output << "flip a#{i} 1 0\n"
    output << "flip b#{i} 1 0\n"
  end
  output << <<ENDC
flip z0 1 10
flip z0 0 4000
done
ENDC

  output.join
end

if __FILE__ == $0
  puts gen_circuit(ARGV[0].to_i)
end
