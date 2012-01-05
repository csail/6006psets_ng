require 'test/unit'
require 'rsa'

class RSATest < Test::Unit::TestCase
  def setup
    basedir = '.'
    @in_files = Dir.glob('./tests/*in')
    @in_files.sort()
  end
  
  def cmp_files(file, lines)
    lines.each do |line|
      if file.gets.strip() != line
        return false
      end
    end
    return file.gets == nil
  end
  
  def testCorrectness
    puts "Testing correctness...."
    @in_files.each do |in_filename|
      test_name = File.basename(in_filename)
      STDOUT.write("Testing #{test_name} .........")
      STDOUT.flush
      in_file = File.open(in_filename)
      image = EncryptedImage.from_file(in_file)
      out_lines = image.to_line_list()
      
      gold_filename = in_filename.sub("in", "gold")
      gold_file = File.open(gold_filename)
      same = self.cmp_files(gold_file, out_lines)
      if same
        STDOUT.write("OK\n")
      else
        STDOUT.write("Failed\n")
      end
      assert same
              
    end
  end

end