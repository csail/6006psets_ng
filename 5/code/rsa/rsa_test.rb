#!/usr/bin/env ruby
require 'test/unit'
require_relative 'rsa'

class RsaTest < Test::Unit::TestCase
  def setup
    dir = File.dirname(__file__)
    # Obtains a list of cross-platform test file paths.
    @_in_files = Dir.glob(File.join(dir, 'tests', '*.in'))
    @_in_files.sort
  end
  
  def _cmp_files(file, lines)
    lines.each do |line|
      return false if line != file.gets.strip
    end        
    file.gets == ''
  end

  def testCorrectness
    print('Testing correctness:')
    @_in_files.each do |in_filename|
      test_name = File.basename(in_filename)
      STDOUT.write('Testing {0} ...... '.format(test_name))
      STDOUT.flush
      begin
        in_file = File.open(in_filename)
        image = EncryptedImage.from_file(in_file)
        out_lines = image.to_line_list
       
        gold_filename = re.sub('\.in$', '.gold', in_filename)
        begin
          gold_file = File.open(gold_filename)
          same = _cmp_files(gold_file, out_lines)
          if same
            STDOUT.write('OK\n')
          else
            STDOUT.write('Failed\n')
          end
          assert_equal(same, true)
        end
      end
    end
  end
  
end

if __FILE__ == $0
  Test::Unit::UI::Console::TestRunner.run(RsaTest)
end  