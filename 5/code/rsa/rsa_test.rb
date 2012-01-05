require 'test/unit'

require_relative 'rsa.rb'

class RsaTest < Test::Unit::TestCase
    
  Dir['tests/*.in'].each do |in_filename|
    define_method :"test_#{in_filename.split('.').first}" do
      test_name = File.basename in_filename
      in_file = File.open in_filename
      image = EncryptedImage.from_file in_file
      out_lines = image.to_line_list
      gold_filename = in_filename.sub "in", "gold"
      assert_equal File.readlines(gold_filename).each(&:strip!), out_lines
    end
  end


end  # class RSATest
