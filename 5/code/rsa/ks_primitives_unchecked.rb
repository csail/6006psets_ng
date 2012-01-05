class Byte
  
  attr_accessor :byte, :hex, :word
  def initialize(value)
    raise 'Do not call the Byte constructor directly!' if Byte.bytes.length == 0x100
    @byte = value
    @hex = Byte.hex_digits[value >> 4, 1] + Byte.hex_digits[value & 0xF, 1]
    @word = nil
  end
  
  @@hex_digits = '0123456789ABCDEF'
  @@nibbles = {'0' => 0, '1' => 1, '2' => 2, '3' => 3, '4' => 4, '5' => 5,
  '6' => 6, '7' => 7, '8' => 8, '9' => 9, 'A' => 10, 'B' => 11, 'C' => 12,
  'D' => 13, 'E' => 14, 'F' => 15}
  @@bytes = []
  
  def self.hex_digits
    @@hex_digits
  end
  def self.nibbles
    @@nibbles
  end
  def self.bytes
    @@bytes
  end
  def self.bytes=(value)
    @@bytes = value
  end
  
  def self.zero
    #a byte initialized to 0
    Byte.bytes[0]
  end
  
  def self.one
    #a byte initialized to 1
    Byte.bytes[1]
  end
  
  def self.from_hex(hex_string)
    #a byte initialized to the value in the given hexadecimal number
    #args
    # string: a 2-char string contaiting the hexadecmial digits 0-9, a-f,
    #         and/or A-F
    #
    
    raise 'Invalid hexadecimal string' if hex_string.length != 2
    d1 = hex_string[0, 1]
    d2 = hex_string[1, 1]
    raise 'Invalid hexadecimal string' if !Byte.nibbles.has_key?(d1) || !Byte.nibbles.has_key?(d2)
    Byte.bytes[(Byte.nibbles[d1] << 4) | Byte.nibbles[d2]]
  end
    
  def self.h(hex_string)
    #shorthand for from_hex(hex_string)
    Byte.from_hex(hex_string)
  end
  
  def hex
    #a 2-char string containing the hexadecimal value of this byte
    @hex
  end
  
  def word
    #a word with the same value as this byte
    @word
  end 
  
  def <(other)
    @byte < other.byte
  end
  
  def <=(other)
    @byte <= other.byte
  end
  
  def >(other)
    @byte > other.byte
  end
  
  def >=(other)
    @byte >= other.byte
  end
  
  def +(other)
    Word.words[(@byte + other.byte) & 0xFFFF]
  end
  
  def -(other)
    Word.words[(0x10000 + @byte - other.byte) & 0xFFFF]
  end
  
  def *(other)
    Word.words[@byte * other.byte]
  end
  
  def /(other)
    self.word/other
  end
  
  def %(other)
    self.word() % other
  end
  
  def &(other)
    Byte.bytes[@byte & other.byte]
  end
  
  def |(other)
    Byte.bytes[@byte | other.byte]
  end
  
  def ^(other)
    Byte.bytes[@byte ^ other.byte]
  end
  
  def to_s
    "0x#{self.hex}"
  end
  
  def inspect
    "Byte.h('#{self.hex}')"
  end
end

i = 0
while i < 0x100 do
  Byte.bytes << Byte.new(i)
  i += 1
end

class Word
  
  attr_accessor :lsb, :msb, :word, :hex
  def initialize(value)
    raise 'Do not call the Word constructor directly!' if Word.words.length == 0x100000
    @word = value
    @lsb = Byte.bytes[@word & 0xFF]
    @msb = Byte.bytes[@word >> 8]
    @hex = self.msb().hex + self.lsb.hex
  end
  
  @@words = []
  
  def self.words
    @@words
  end
  
  def self.words=(value)
    @@words = value
  end
    
    
  def self.zero
    #a word initialized to 0
    Word.words[0]
  end
  
  def self.one
    #a word initialized to 1
    Word.words[1]
  end
  
  def self.from_byte(byte)
    #a word initialized to the value of a Byte
    Word.words[byte.byte]
  end
  
  def self.from_bytes(msb, lsb)
    #a word initialized from two Bytes. (msb:lsb)
    Word.words[(msb.byte << 8) | lsb.byte]
  end
  
  def self.from_hex(hex_string)
    #a word initialized to the value in the given hexadecimal number
    #args:
    #    string: a 2-char string containing the hexadecimal digits 0-9, a-f,
    #            and/or A-F
    #
    raise 'Invalid hexadecimal string' if hex_string.length != 4
    Word.from_bytes(Byte.from_hex(hex_string[0, 2]), Byte.from_hex(hex_string[2,2]))
  end
  
  def self.h(hex_string)
    Word.from_hex(hex_string)
  end
  
  def hex
    #a 4-char string containing the hexadecmial value of this word
    @hex
  end
  
  def lsb
    #the word's least significant byte
    @lsb
  end
  
  def msb
    @msb
  end
  
  def <(other)
    return @word < other.word
  end
  
  def <=(other)
    return @word <= other.word
  end
  
  def >(other)
    return @word > other.word
  end
  
  def >=(other)
    return @word >= other.word
  end
  
  def +(other)
    Word.words[(@word + other.word) & 0xFFFF]
  end
  
  def -(other)
    Word.words[(0x10000 + @word - other.word) & 0xFFFF]
  end
  
  def /(other)
    Byte.bytes[(@word / other.byte) & 0xFF]
  end
  
  def %(other)
    Byte.bytes[@word % other.byte]
  end
  
  def &(other)
    Word.words[@word & other.word]
  end
  
  def |(other)
    Word.words[@word | other.word]
  end
  
  def ^(other)
    return Word.words[@word ^ other.word]
  end
  
  def to_s
    "0x#{self.hex()}"
  end
  
  def inspect
    "Word.h('#{self.hex()}')"
  end
end
    
    
  
i = 0
while i < 0x10000 do
  Word.words << Word.new(i)
  i += 1
end

i = 0
while i < 0x100 do
  Byte.bytes[i].word = Word.words[i]
  i += 1
end
    
    
    
    
    



