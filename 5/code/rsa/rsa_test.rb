#!/usr/bin/env ruby

require 'test/unit'
require_relative 'rsa.rb'

class RsaTest < Test::Unit::TestCase
  def setup
    dir = File.dirname(__FILE__)
    # Obtains a list of cross-platform test file paths.
    @_in_files = Dir.glob(File.join(dir, 'tests', '*.in')).sort!
  end

  def testCorrectness
    print('Testing correctness:')
    @_in_files.each do |in_filename|
      test_name = File.basename(in_filename)
      
      begin
        in_file = File.open(in_filename)
        image = EncryptedImage.from_io(in_file)
        out_lines = image.to_line_list
       
        gold_filename = in_filename.sub(/.in/, '.gold')
        begin
          gold_file = File.open(gold_filename)
          assert_equal File.readlines(gold_file).each(&:strip!), out_lines
          assert same
        end
      end
    end
  end
  
end
