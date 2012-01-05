Circuit Layout Verification code for MIT 6.006 Fall 2011 PS3

The code distribution contains the following files:
  * circuit.{py, rb} - pset (stripped) versions of the circuit layout verifier
  * full_circuit.{py, rb} - full implementations of the circuit layout verifier
  * circuit_test.rb - unit test for circuit.py
  * good_trace.jsonp - trace for the sweep-line algorithm on the 6.006 logo test
  * test/*.in - circuit simulator test inputs
  * test/*.gold - outputs that we believe to be correct for the test inputs
  * test/README.txt - instructions for creating new test cases
  * visualizer/bin/visualizer.html - visualizes the simulator output
  * visualizer/README.txt - Readme for the visualizer source code
  * visualizer/* - visualizer source code
  * distribute.rake - copies the pset files in distribution/
  * devadas_test_gen.rb - generates the circuit in the Devadas paper
  * sort_test_gen.rb - generates a bitonic mergesort network
  * Rakefile - benchmarks the circuit simulator in various Ruby and Python VMs


USAGE

circuit.py's behavior can be tweaked using the QUEUE environment variable, which
chooses the heap implementation used by the circuit simulator. The following
values are recognized:
* blit - reverse sorted array heap; O(N) / insertion, with small constant
* heap - 6.006-staff heap implementation; O(log N) / operation
* lib - python's heapq library; O(log N) / operation
* slow (default) - unordered array heap; O(1) / insertion, O(N) / extract-min

Command-line example:
    QUEUE=blit python2.7 circuit.py < tests/1gate.in


circuit.rb honors the following environment variables:
* QUEUE works just like in circuit.py, except QUEUE=lib uses a heap based on the
rbtree Ruby gem (rbtree-pure can be used instead of rbtree, outside of MRI)
* TRACE=stats outputs performance statistics instead of the simulation output;
useful for ensuring that test cases are good
* TRACE=jsonp outputs a JSON file for the visualizer
* DEBUG=true outputs each heap operation; useful for debugging heap
implementations

Command-line example:
    rvm 1.8.7 exec env QUEUE=blit ./circuit.rb < tests/1gate.in


devadas_test_gen.rb takes one command-line argument, the depth of the circuit.
Simulating the Devadas circuit will result a number of transitions that is
exponential in the circuit depth.

Command-line example:
    ./devadas_test_gen.rb 13 > tests/5devadas13.in


sort_test_gen.rb takes one command-line argument, the number of inputs for the
sorting network. The number of inputs must be a power of two.

Command-line example:
    ./sort_test_gen.rb 128 > tests/7sort128.in


layout.rb is documented in tests/README.txt 


The Rakefile generates benchmarks in the bench directory. bench/summary*.csv can
be used to generate pretty graphs.

Command-line example:
    rake


DEPENDENCIES

circuit.py has been tested on Python 2.7, Python 3.2, and PyPy 1.5.

circuit.rb has been tested on Ruby 1.8.7, Ruby 1.9.2, JRuby 1.6.3, and
Rubinius 1.2.4. It requires RubyGems, the json gem (on 1.8), and the rbtree or
rbtree-pure gem. 

The test generators should work in any recent Ruby.

Generating benchmarks with the Rakefile requires the rake gem. It assumes
RVM  (the ruby VM manager), with the following VMs installed: 1.8.7, 1.9.2,
1.9.3, jruby, rbx, rbx-2.0.0pre. It also assumes that Python 2.7, Python 3.2 and
PyPy are installed and available in $PATH.
