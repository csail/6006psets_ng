# An 8-bit digit. (base 256)
class Byte
  include Comparable
  attr_accessor :to_word
  attr_reader :byte, :to_hex
 
  # Do not call the Byte constructor directly.
  #
  # Use Byte.zero, Byte.one, Byte.from_hex instead.
  def initialize(value)
    raise 'Do not call the Byte constructor directly!' if Byte.bytes.length == 0x100
    @byte = value
    @to_hex = '%02X' % value
    @to_word = nil
    #@@bytes = [] 
  end
    
  # Private: array of singleton Byte instances.
  @@bytes = []
  
  def self.bytes
    @@bytes
  end
  
  def self.bytes=(value)
    @@bytes = value
  end
  
  # A byte initialized to 0.
  def self.zero
    Byte.bytes[0]
  end
  
  # A byte initialized to 1.
  def self.one
    Byte.bytes[1]
  end
  
  # A byte initialized to the value in the given hexadecimal number.
  #
  # Args:
  #   string:: a 2-character string containing the hexadecimal digits 0-9, a-f,
  #            and/or A-F
  def self.from_hex(hex_string)
    #a byte initialized to the value in the given hexadecimal number
    #args
    # string: a 2-char string contaiting the hexadecmial digits 0-9, a-f,
    #         and/or A-F
    #
    
    raise 'Invalid hexadecimal string' if hex_string.length != 2
    Byte.bytes[Kernel.Integer(hex_string, 16)]
  end
  
  # Shorthand for from_hex(hex_string).
  def self.h(hex_string)
    Byte.from_hex hex_string
  end
  
  # <=> for Bytes.
  def <=>(other)
    @byte <=> other.byte
  end
  
  # Returns a Word with the result of adding 2 Bytes.
  def +(other)
    Word.words[(@byte + other.byte) & 0xFFFF]
  end
  
  # Returns a Word with the result of subtracting 2 Bytes.
  def -(other)
    Word.words[(0x10000 + @byte - other.byte) & 0xFFFF]
  end
  
  # Returns a Word with the result of multipling 2 Bytes.
  def *(other)
    Word.words[@byte * other.byte]
  end
  
  # Returns a Byte with the division quotient of 2 Bytes.
  def /(other)
    @to_word / other
  end
  
  # Returns a Byte with the division remainder of 2 Bytes.
  def %(other)
    @to_word % other
  end
  
  # Returns a Byte with the logical AND of two Bytes.
  def &(other)
    Byte.bytes[@byte & other.byte]
  end
  
  # Returns a Byte with the logical OR of two Bytes.
  def |(other)
    Byte.bytes[@byte | other.byte]
  end
  
  # Returns a Byte with the logical XOR of two Bytes.
  def ^(other)
    Byte.bytes[@byte ^ other.byte]
  end
  
  # Debugging help: returns the Byte formatted as "0x??".
  def to_s # :nodoc:
    "0x#{@to_hex}"
  end
  
  # Debuging help: returns a Ruby expression that can create this Byte.
  def inspect # :nodoc:
    "Byte.h('#{@to_hex}')"
  end
end  # class Byte

# A 16-bit digit. (base 65536)
class Word
  include Comparable
  attr_reader :lsb, :msb, :word, :to_hex
  
  # Do not call the Word constructor directly.
  # Use Word.zero, Byte.one, Byte.from_hex instead
  def initialize(value)
    raise 'Do not call the Word constructor directly!' if Word.words.length == 0x100000
    @word = value
    @lsb = Byte.bytes[@word & 0xFF]
    @msb = Byte.bytes[@word >> 8]
    @to_hex = self.msb.to_hex + self.lsb.to_hex
  end
  
  # Private: array of singleton Word instances
  @@words = []
  
  def self.words
    @@words
  end
  
  def self.words=(value)
    @@words = value
  end
    
  # A word initialized to 0.
  def self.zero
    Word.words[0]
  end
  
  # A word initialized to 1.
  def self.one
    Word.words[1]
  end
  
  # A word initialized to the value of a Byte.
  def self.from_byte(byte)
    Word.words[byte.byte]
  end
  
  # A word initialized from two Bytes. (msb:lsb)
  def self.from_bytes(msb, lsb)
    Word.words[(msb.byte << 8) | lsb.byte]
  end
  
  # A word initialized to the value in the given hexadecimal number.
  # Args:
  #   string:: a 2-char string containing the hexadecimal digits 0-9, a-f,
  #            and/or A-F
  def self.from_hex(hex_string)
    raise 'Invalid hexadecimal string' if hex_string.length != 4
    Word.from_bytes Byte.from_hex(hex_string[0, 2]), Byte.from_hex(hex_string[2,2])
  end
  
  def self.h(hex_string)
    Word.from_hex hex_string
  end
  
  # <=> for Words.
  def <=>(other)
    @word <=> other.word
  end
  
  # Returns a Word with the result of adding 2 Words modulo 65,536
  def +(other)
    Word.words[(@word + other.word) & 0xFFFF]
  end
  
  # Returns a Word with the result of subtracting 2 Words modulo 65,536
  def -(other)
    Word.words[(0x10000 + @word - other.word) & 0xFFFF]
  end
  
  # Returns a Byte with the division quotient between this Word and a Byte.
  def /(other)
    Byte.bytes[(@word / other.byte) & 0xFF]
  end
  
  # Returns a Byte with the division remainder between this Word and a Byte.
  def %(other)
    Byte.bytes[@word % other.byte]
  end
  
  # Returns the logical AND of two Words.
  def &(other)
    Word.words[@word & other.word]
  end
  
  # Returns the logical OR of two Words.
  def |(other)
    Word.words[@word | other.word]
  end
  
  # Returns the logical XOR of two Words.
  def ^(other)
    Word.words[@word ^ other.word]
  end
  
  # Debugging help: returns the Byte formatted as "0x????".
  def to_s # :nodoc:
    "0x#{@to_hex}"
  end
  
  # Debuging help: returns a Ruby expression that can create this Word.
  def inspect # :nodoc:
    "Word.h('#{@to_hex}')"
  end
end  # class Word
    
    
# Private: initialize singleton Byte instances.s
0.upto(0xFF) { |i| Byte.bytes << Byte.new(i) }

# Private: initialize singleton Word instances
0.upto(0xFFFF) { |i| Word.words << Word.new(i) }

# Private: link Byte instances to their corresponding Words.
0.upto(0xFF) { |i| Byte.bytes[i].to_word = Word.words[i] }
