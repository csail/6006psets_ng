#!/usr/bin/env ruby

#Interface to low-level arithmetic functionality in KS cores.
class Byte
  include Comparable
  attr_reader :_hex, :_word
  
  # Private: maps nibbles to hexadecimal digit strings.
  @_hex_digits = '0123456789ABCDEF'

  # Private: maps hexadecimal digit strings to nibbles.
  @_nibbles = {'0' => 0, '1'=> 1, '2'=> 2, '3'=> 3, '4'=> 4, '5'=> 5, '6'=> 6, '7'=> 7,
              '8'=> 8, '9'=> 9,
              'A'=> 10, 'B'=> 11, 'C'=> 12, 'D'=> 13, 'E'=> 14, 'F'=> 15,
              'a'=> 10, 'b'=> 11, 'c'=> 12, 'd'=> 13, 'e'=> 14, 'f'=> 15}
  
  # Private: array of singleton Byte instances.
  @@_bytes = []
  
  def initialize value
    raise ValueError, "Do not call the Byte constructor directly!" if Byte._bytes.length == 0x100
    
    @_byte = value
    @_hex = Byte._hex_digits[value >> 4] + Byte._hex_digits[value & 0xF]
    @_word = nil
  end
  
  def self.zero
    #'''A byte initialized to 0.'''
    Byte._bytes[0]
  end
  
  ##static method??
  def self.one
    #'''A byte initialized to 1.'''
    Byte._bytes[1]
  end
  
  #A byte initialized to the value in the given hexadecimal number.
  #Args:
  #string: a 2-character string containing the hexadecimal digits 0-9, a-f, and/or A-F
  
  def self.from_hex(hex_string)
    raise ValueError, 'Invalid hexadecimal string' if hex_string.length != 2
    d0 = hex_string[0]
    d1 = hex_string[1]
    raise ValueError, 'Invalid hexadecimal string' if not Byte._nibbles.include?(d0 || d1)
    Byte._bytes[(Byte._nibbles[d1] << 4) | Byte._nibbles[d2]]
  end
  
  #Shorthand for from_hex(hex_string)
  def self.h(hex_string)
    Byte.from_hex(hex_string)
  end
  
  def <=>(other)    
    raise NotImplementedError if not other.instance_of?(Byte)
    @_byte <=> other._byte
  end
  
  def +(other)
    raise NotImplementedError if not other.instance_of?(Byte)
    Word._words[(@_byte + other._byte) & 0xFFFF]
  end
  
  def -(other)
    raise NotImplementedError if not other.instance_of?(Byte)
    Word._words[(0x10000 + @_byte - other._byte) & 0xFFFF]
  end

  def *(other)
    raise NotImplementedError if not other.instance_of?(Byte)
    Word._words[@_byte * other._byte]
  end
  
  def divmod(other)
    raise NotImplementedError if not other.instance_of?(Byte)
    divmod(word, other)
  end
  
  def /(other)
    raise NotImplementedError if not other.instance_of?(Byte)
    word / other
  end
  
  def modulo(other)
    raise NotImplementedError if not other.instance_of?(Byte)
    word % other
  end
  
  def &(other)
    raise NotImplementedError if not other.instance_of?(Byte)
    Byte._bytes[@_byte & other._byte]
  end

  def |(other)
     raise NotImplementedError if not other.instance_of?(Byte)
     Byte._bytes[@_byte | other._byte]
  end
  
  def ^(other)
    raise NotImplementedError if not other.instance_of?(Byte)
    Byte._bytes[@_byte ^ other._byte]
  end
  
  def inspect ##repr
    raise NotImplementedError if not other.instance_of?(Byte)
    "Byte.h('#{self.hex}')"
  end
  
  def to_s 
    "0x#{hex}"
  end
  

end



class Word
  include Comparable
  attr_reader :_hex, :_lsb, :_msb
  
  @@_words = []
  
  def initialize(value)
    @_word = value
    @_lsb = Byte._bytes[self._word & 0xFF]
    @_msb = Byte._bytes[self._word >> 8]
    @_hex = Byte.hex(self.msb()) + Byte.hex(self.lsb())
  end

  def self.zero
    #'''A byte initialized to 0.'''
    Word._words[0]
  end
  
  def self.one
    #'''A byte initialized to 1.'''
    Word._words[1]
  end
  
  def self.from_byte(byte)
    raise ValueError, 'The argument is not a Byte' if not byte.instance_of?(Byte)
    Word._words[byte._byte]
  end
  
  def self.from_bytes(msb, lsb)
    raise ValueError, 'The arguments are not both Bytes' if not (msb and lsb).instance_of?(Byte)
  end
  
  def self.from_hex(hex_string)
    raise ValueError, 'Invalid hexadecimal string' if hex_string.length != 4
    Word.from_bytes(Byte.from_hex(hex_string[0..2]),Byte.from_hex(hex_string[2..4]))
  end
  
  def self.h(hex_string)
    Word.from_hex(hex_string)
  end
  
  def hex
    _hex
  end
  
  def lsb
    _lsb
  end
  
  def msb
    _msb
  end
  
  def <=>(other)
    return NotImplementedError if not other.instance_of?(Word)
    @_word <=> other._word
  end
  
  def +(other)
    return NotImplementedError if not other.instance_of?(Word)
    Word._words[(@_word + other._word) & 0xFFFF]
  end

  def -(other)
    return NotImplementedError if not other.instance_of?(Word)
    Word._words[(@_word - other._word) & 0xFFFF]
  end
  
  def *(other)
    NotImplementedError
  end
  
  def divmod(other)
    return NotImplementedError if not other.instance_of?(Word)
    Byte._bytes[divmod(@_word, other._byte) & 0xFF]
  end
  
  def /(other)
    return NotImplementedError if not other.instance_of?(Word)
    Byte._bytes[(@_word / other._byte) & 0xFF]
  end
  
  def modulo(other)
    return NotImplementedError if not other.instance_of?(Word)
    Byte._bytes[@_word % other._word]
  end
  
  def &(other)
    return NotImplementedError if not other.instance_of?(Word)
    Word._words[@_word & other._word]
  end
  
  def |(other)
    return NotImplementedError if not other.instance_of?(Word)
    Word._words[@_word | other._word]
  end
  
  def ^(other)
    return NotImplementedError if not other.instance_of?(Word)
    Word._words[@_word ^ other._word]
  end
  
  def to_a
    "0x#{hex}"
  end
  
  def inspect
    "Word.h('#{hex}')"
  end

end

  
# Private: initialize singleton Byte instances.
0..0x100.each do |i|
  Byte._bytes.append(Byte(i))
end

# Private: initialize singleton Word instances.
0..0x10000.each do |i|
  Word._words.append(Word(i))
end

# Private: link Byte instances to their corresponding Words.
0..0x100.each do |i|
  Byte._bytes[i]._word = Word._words[i]
end

