require 'test/unit'
require 'rsa'

class RSATest < Test::Unit::TestCase
  def setup
    basedir = '.'
    @in_files = Dir.glob './tests/*in'
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
  
  define_method(:test_a_file) do |in_filename|
    test_name = File.basename in_filename
    STDOUT.write "Testing #{test_name}......."
    STDOUT.flush
    in_file = File.open in_filename
    image = EncryptedImage.from_file in_file
    out_lines = image.to_line_list
    gold_filename = in_filename.sub "in", "gold"
    gold_file = File.open gold_filename
    same = self.cmp_files gold_file, out_lines
    STDOUT.write same ? "OK\n" : "Failed\n"
    assert same
  end
  
  def test_all_filse
    @in_files.each do |in_filename|
      self.test_a_file(in_filename)
    end
  end
end # class RSATest
