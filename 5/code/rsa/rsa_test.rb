#!/usr/bin/env ruby

require 'test/unit'
require './rsa.rb'

class RsaTest < Test::Unit::TestCase
  def setup
    dir = File.dirname(__FILE__)
    # Obtains a list of cross-platform test file paths.
    @_in_files = Dir.glob(File.join(dir, 'tests', '*.in')).sort!
  end

  def test_correctness
    @_in_files.each do |in_filename|
      test_name = File.basename(in_filename)
        in_file = File.open(in_filename)
        image = EncryptedImage.from_io(in_file)
        out_lines = image.to_line_list
        gold_filename = in_filename.sub(/.in/, '.gold')
        assert_equal File.readlines(gold_filename).each(&:strip!), out_lines
    end
  end
end  # class Test::Unit::TestCase::RsaTest
