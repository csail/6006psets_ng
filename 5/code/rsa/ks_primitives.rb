#!/usr/bin/env ruby

#Interface to low-level arithmetic functionality in KS cores.
# WARNING: the mock implementation below is intended to allow running KS code on
#non-KS hardware. Do NOT rely on any private members in the code below. The KS
#Python VM compiles these objects into hardware primitives. For example,
#accessing the _byte property of a Byte will raise an exception in the KS Python
#VM.

# An 8-bit digit. (base 256)
class Byte
  include Comparable
  attr_reader :_hex, :_bytes, :_byte, :_word
  private :_bytes
  
  # Private: array of singleton Byte instances.
  @@_bytes = []
  
  # Private: maps hexadecimal digit strings to nibbles.
  @@_nibbles = {'0' => 0, '1'=> 1, '2'=> 2, '3'=> 3, '4'=> 4, '5'=> 5, '6'=> 6, '7'=> 7,
              '8'=> 8, '9'=> 9,
              'A'=> 10, 'B'=> 11, 'C'=> 12, 'D'=> 13, 'E'=> 14, 'F'=> 15,
              'a'=> 10, 'b'=> 11, 'c'=> 12, 'd'=> 13, 'e'=> 14, 'f'=> 15}
  
  # Do not call the Byte constructor directly.
  # Use Byte.zero(), Byte.one(), or Byte.from_hex() instead.
  def initialize(value)
    raise "Do not call the Byte constructor directly!" if @@_bytes.length == 0x100
    
    @_byte = value
    @_hex = '%02X' % value
    @_word = nil
  end
    
  def self._bytes
    @@_bytes
  end
  
  def self._bytes=(val) 
    @@_bytes = val
  end

  # A byte initialized to 0.
  def self.zero
    @@_bytes[0]
  end
  
  # A byte initialized to 1.
  def self.one
    @@_bytes[1]
  end
  
  #A byte initialized to the value in the given hexadecimal number.
  #
  #Args: string: a 2-character string containing the hexadecimal 
  # digits 0-9, a-f, and/or A-F
  def self.from_hex hex_string
    raise 'Invalid hexadecimal string' if hex_string.length != 2
    d0 = hex_string[0]
    d1 = hex_string[1]
    raise 'Invalid hexadecimal string' unless @@_nibbles.include?(d0 || d1)
    @@_bytes[(@@_nibbles[d0] << 4) | @@_nibbles[d1]]
  end
  
  #Shorthand for from_hex(hex_string)
  def self.h(hex_string)
    from_hex hex_string
  end
  
  # A 2-character string containing the hexadecimal value of this byte.
  def hex
    _hex
  end
  
  # A Word with the same value as this Byte.
  def to_word
    _word
  end
  
  # :nodoc: <=> for Bytes
  def <=>(other)
    raise ArgumentError unless other.instance_of? Byte
    @_byte <=> other._byte
  end
  
  # Returns a Word with the result of adding 2 Bytes.
  def +(other)
    raise ArgumentError unless other.instance_of? Byte
    Word._words[(@_byte + other._byte) & 0xFFFF]
  end
  
  # Returns a Word with the result of subtracting 2 Bytes.
  def -(other)
    raise ArgumentError unless other.instance_of? Byte
    Word._words[(0x10000 + @_byte - other._byte) & 0xFFFF]
  end

  # Returns a Word with the result of multiplying 2 Bytes.
  def *(other)
    raise ArgumentError unless other.instance_of? Byte
    Word._words[@_byte * other._byte]
  end
  
  # Returns a Byte with the division quotient of 2 Bytes.
  def /(other)
    raise ArgumentError unless other.instance_of? Byte
    #_word.divmod(other._word)[0]
    @_word / other
  end
  
  # Returns a Byte with the division remainder of 2 Bytes.
  def %(other)
    raise ArgumentError unless other.instance_of? Byte
    #_word.divmod(other._word)[1]
    @_word % other
  end
  
  # Returns a Byte with the logical AND of two Bytes.
  def &(other)
    raise ArgumentError unless other.instance_of? Byte
    @@_bytes[@_byte & other._byte]
  end

  # Returns a Byte with the logical OR of two Bytes.
  def |(other)
     raise ArgumentError unless other.instance_of? Byte
    @@_bytes[@_byte | other._byte]
  end
  
  # Returns a Byte with the logical XOR of two Bytes.
  def ^(other)
    raise ArgumentError unless other.instance_of? Byte
    @@_bytes[@_byte ^ other._byte]
  end
  
  # :nodoc: Debugging help: returns a Python expression that can create this Byte.
  def inspect
    "Byte.h('#{self.hex}')"
  end
  
  # :nodoc: Debugging help: returns the Byte formatted as "0x??".
  def to_s 
    "0x#{hex}"
  end

end




# A 16-bit digit. (base 65536)
class Word
  include Comparable
  attr_reader :_hex, :_lsb, :_msb, :_words, :_word

  @@_words = []
  
  # Do not call the Word constructor directly.
  # Use Word.zero(), Byte.one(), or Byte.from_hex() instead.
  def initialize(value)
    @_word = value
    @_lsb = Byte._bytes[@_word & 0xFF]
    @_msb = Byte._bytes[@_word >> 8]
    @_hex = @_msb.hex + @_lsb.hex
  end
  
  def self._words
    @@_words
  end

  def self._words=(val)
    @@_words = val
  end

  # A word initialized to 0.
  def self.zero
    @@_words[0]
  end

  # A word initialized to 1.  
  def self.one
    @@_words[1]
  end
  
  # A word initialized to the value of a Byte.
  def self.from_byte(byte)
    raise 'The argument is not a Byte' unless byte.instance_of? Byte
    @@_words[byte._byte]
  end
  
  # A word initialized from two Bytes. (msb:lsb)
  def self.from_bytes(msb, lsb)
    raise 'The arguments are not both Bytes' unless (msb and lsb).instance_of? Byte
    @@_words[(msb._byte << 8) | lsb._byte]
  end
  
  #  A word initialized to the value in the given hexadecimal number. 
  #
  #  Args:
  #    string: a 2-character string containing the hexadecimal digits 0-9, a-f,
  #            and/or A-F
  def self.from_hex(hex_string)
    raise 'Invalid hexadecimal string' if hex_string.length != 4
    from_bytes Byte.from_hex(hex_string[0, 2]), Byte.from_hex(hex_string[2, 2])
  end
  
  # Shorthand for from_hex(hex_string).
  def self.h(hex_string)
    from_hex hex_string 
  end
  
  # A 4-character string containing the hexadecimal value of this word.
  def hex
    _hex
  end
  
  # The word's least significant Byte.
  def lsb
    _lsb
  end
  
  # The word's most significant Byte.
  def msb
    _msb
  end
  
  # <=> for Words.
  def <=>(other)
    raise ArgumentError unless other.instance_of? Word
    @_word <=> other._word
  end
  
  # Returns a Word with the result of adding 2 Words modulo 65,536.
  def +(other)
    raise ArgumentError unless other.instance_of? Word
    @@_words[(@_word + other._word) & 0xFFFF]
  end

  # Returns a Word with the result of subtracting 2 Words modulo 65,536.
  def -(other)
    raise ArgumentError unless other.instance_of? Word
    @@_words[(@_word - other._word) & 0xFFFF]
  end
  
  # Do not call. Multiply two Bytes to obtain a Word.
  def *(other)
    raise ArgumentError
  end
  
  # Returns a Byte with the division quotient between this Word and a Byte.
  def /(other)
    raise ArgumentError unless other.instance_of? Byte
    Byte._bytes[(@_word / other._byte) & 0xFF]
  end
  
  # Returns a Byte with the division remainder between this Word and a Byte.
  def %(other)
    raise ArgumentError unless other.instance_of? Byte
    Byte._bytes[@_word % other._byte]
  end
  
  # Returns a Word with the logical AND of two Words.
  def &(other)
    raise ArgumentError unless other.instance_of? Word
    @@_words[@_word & other._word]
  end
  
  # Returns a Word with the logical OR of two Words.
  def |(other)
    raise ArgumentError unless other.instance_of? Word
    @@_words[@_word | other._word]
  end
  
  # Returns a Word with the logical XOR of two Words.
  def ^(other)
    raise ArgumentError unless other.instance_of? Word
    @@_words[@_word ^ other._word]
  end
  
  # :nodoc: Debugging help: returns the Byte formatted as "0x????".
  def to_s
    "0x#{hex}"
  end
  
  # :nodoc: Debugging help: returns a Python expression that can create this Word.
  def inspect
    "Word.h('#{hex}')"
  end

end


Byte.class_eval do
  # Private: initialize singleton Byte instances.
  0.upto 0xFF do |i|
    Byte._bytes << Byte.new(i)
  end
end

Word.class_eval do
  # Private: initialize singleton Word instances.
  0.upto 0xFFFF do |i|
    Word._words << Word.new(i)
  end
end

Byte.class_eval do
  # Private: link Byte instances to their corresponding Words.
  0.upto 0xFF do |i|
    Byte._bytes[i].instance_variable_set(:@_word, Word._words[i])
    #Byte._bytes[i]._word = Word._words[i]
  end
end