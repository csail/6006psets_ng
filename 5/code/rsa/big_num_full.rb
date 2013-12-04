#!/usr/bin/env ruby

if ENV['KS_DEBUG'] and ENV['KS_DEBUG'] != 'false'
  require './ks_primitives.rb'
else
  require './ks_primitives.rb'  # TODO: rename to './ks_primitives_unchecked.rb'
end

# Large number arithmetic optimized for KS cores.
class BigNum < Object
  include Comparable
  attr_reader :d  # Large number implemented as a little-endian array of Bytes
  protected :d
  attr_accessor :inverse, :inverse_precision
  protected :inverse, :inverse_precision
  
  # Creates a BigNum from a sequence of digits.
  #
  # Args:
  #    digits:: the Bytes used to populate the BigNum
  #    size:: if set, the BigNum will only use the first "size" elements of 
  #        digits
  #    no_copy:: uses the "digits" argument as the backing store for BigNum, if
  #        appropriate (meant for internal use inside BigNum)
  def initialize(digits, size = nil, no_copy = false) 
    @d = (no_copy and digits.length == size) ? digits : digits.dup
    
    # Used by the Newton-Raphson division code.
    @inverse = nil
    @inverse_precision = nil
    
    size ||= digits.length
    if size < 0 
      raise ValueError, "BigNums cannot hold a negative amount of digits"  
    end
    size = 1 if size == 0
    @d << Byte.zero while @d.length < size
  end
  
  # Checks to make sure that the other argument in the operation is a BigNum.
  # Otherwise, the operation will not work.
  def self.ensure_bignum!(other)
    unless other.instance_of? BigNum
      raise ArgumentError, "Expected BigNum, got #{other.class}"
    end
  end
  
  # BigNum representing the number 0 (zero).
  def self.zero(size = 1)
    BigNum.new Array.new(size, Byte.zero), size, true
  end
  
  # BigNum representing the number 1 (one).
  def self.one(size = 1)
    digits = Array.new size, Byte.zero
    digits[0] = Byte.one
    BigNum.new digits, size, true
  end
  
  # BigNum representing the given hexadecimal number.
  #
  # Args:
  #    hex_string:: string containing the desired number in hexadecimal; the 
  #        allowed digits are 0-9, A-F, a-f.
  def self.from_hex(hex_string)
    digits = []
    hex_string.length.step 1, -2 do |i|
      if i == 1
        byte_string = "0#{hex_string[0]}"
      else
        byte_string = hex_string[i - 2, 2]
      end
      digits << Byte.from_hex(byte_string)
    end
    BigNum.new digits, nil, true
  end
  
  # Shorthand for from_hex(hex_string).
  def self.h(hex_string)
    from_hex hex_string
  end
  
  # Hexadecimal string representing this BigNum.
  #
  # This method does not normalize the BigNum, because it is used during
  #     debugging.
  def to_hex
    start = @d.length - 1
    start -= 1 while start > 0 and @d[start] == Byte.zero
    @d[0, start + 1].reverse.map(&:to_hex).join
  end
  
  # Comparing BigNums normalizes them.
  def ==(other)
    return false unless other.instance_of? BigNum
    normalize
    other.normalize
    @d == other.d    
  end
  
  # Comparing BigNums normalizes them.
  def <=>(other)
    BigNum.ensure_bignum! other
    normalize
    other.normalize
    
    return @d.length <=> other.d.length if @d.length != other.d.length 
    
    (@d.length - 1).downto -1 do |i|
      return @d[i] <=> other.d[i] if @d[i] != other.d[i]
    end
    0  # if equal
  end
  
  # This BigNum, with "digits" 0 digits appended at the end. 
  # 
  # Shifting to the left multiplies the BigNum by 256 ** digits.
  def <<(digits)
    new_digits = Array.new digits, Byte.zero
    new_digits.concat @d
    BigNum.new new_digits, nil, true
  end
  
  # This BigNum, without the last "digits" digits.
  # 
  # Shifting to the right divides the BigNum by 256 ** digits.
  def >>(digits)
    return BigNum.zero if digits >= @d.length
    BigNum.new @d[digits..-1], nil, true
  end
  
  # Adding numbers does not normalize them. However, the result is normalized.
  def +(other)
    BigNum.ensure_bignum! other
    if @d.length >= other.d.length
      result = BigNum.zero(1 + @d.length)
    else 
      result = BigNum.zero(1 + other.d.length)
    end
    carry = Byte.zero
    
    0.upto(result.d.length - 1) do |i|
      a = (i < @d.length) ? @d[i] + carry : carry.to_word
      b = (i < other.d.length) ? other.d[i].to_word : Word.zero
      word = a + b
      result.d[i] = word.lsb
      carry = word.msb
    end
    
    result.normalize  
  end
  
  # Subtraction is done using 2's complement.
  # 
  # Subtracting numbers does not normalize them. However, the result is
  #     normalized.
  def -(other)
    BigNum.ensure_bignum! other
    if @d.length >= other.d.length
      result = BigNum.zero @d.length
    else 
      result = BigNum.zero other.d.length
    end
    
    carry = Byte.zero
    0.upto(result.d.length - 1) do |i|
      a = (i < @d.length) ? @d[i].to_word : Word.zero
      b = (i < other.d.length) ? other.d[i] + carry : carry.to_word
        
      word = a - b
      result.d[i] = word.lsb
      carry = (a < b) ? Byte.one : Byte.zero
    end
    
    result.normalize  
  end
  
  # Multiplying numbers does not normalize them. However, the result is
  #     normalized.
  def *(other)
    BigNum.ensure_bignum! other
    if @d.length <= 64 or other.d.length <= 64
      return slow_mul other
    else
      return fast_mul other
    end
  end
  
  # Slow method for multiplying two numbers w/ good constant factors.
  def slow_mul(other)
    fast_mul other
  end
  
  # Asymptotically fast method for multiplying two numbers.
  def fast_mul(other)
    in_digits = [@d.length, other.d.length].max
    if in_digits == 1
      product = @d.first * other.d.first
      return BigNum.new [product.lsb, product.msb], 2, true
    end      
    
    split = in_digits / 2
    self_low = BigNum.new self.d[0...split], nil, true
    self_high = BigNum.new self.d[split..-1], nil, true
    other_low = BigNum.new other.d[0...split], nil, true
    other_high = BigNum.new other.d[split..-1], nil, true
    
    result_high_high = self_high * other_high
    result_low = self_low * other_low
    result_high = (self_low + self_high) * (other_low + other_high) - 
        (result_high_high + result_low)
    ((result_high_high << (2 * split)) + (result_high << split) + 
        result_low).normalize
  end
  
  # Dividing numbers normalizes them. The result is also normalized.
  def /(other)
    BigNum.ensure_bignum! other
    divmod(other).first
  end  
  
  # Multiplying numbers does not normalize them. However, the result is
  #     normalized.
  def %(other)
    BigNum.ensure_bignum! other
    divmod(other)[1]
  end  
  
  # Dividing numbers normalizes them. The result is also normalized.
  def divmod(other)
    BigNum.ensure_bignum! other
    normalize
    other.normalize
    if @d.length <= 256 or other.d.length <= 256
      return slow_divmod(other)
    else
      return fast_divmod(other)
    end 
  end
  
  # Slow method for dividing two numbers with good constant factors.
  def slow_divmod(other)
    fast_divmod other
  end  
  
  # Ensures existence of an inverse in other.
  def ensure_inverse_exists(other)
    if other.inverse == nil
      # First approximation: the inverse of the first digit in the divisor + 1,
      # because 1 / 2xx is <= 1 / 200 and > 1 / 300.
      base = Word.from_bytes Byte.one, Byte.zero
      msb_plus = (other.d.last + Byte.one).lsb
      if msb_plus == Byte.zero
        msb_inverse = (base - Word.one).lsb
        other.inverse_precision = other.d.length + 1
      else
        msb_inverse = base / msb_plus
        other.inverse_precision = other.d.length
      end
      other.inverse = BigNum.new [msb_inverse], 1, true
    end
  end
  
  # Provides a better multiplicative inverse approximation for other
  def improve_inverse(other)
      old_inverse = other.inverse
      old_precision = other.inverse_precision
      other.inverse = ((old_inverse + old_inverse) << old_precision) - 
          (other * old_inverse * old_inverse)
      other.inverse.normalize
      other.inverse_precision *= 2
      
      # Trim zero digits at the end; they don't help.
      zero_digits = 0
      zero_digits += 1 while other.inverse.d[zero_digits] == Byte.zero
      
      if zero_digits > 0
        other.inverse = other.inverse >> zero_digits
        other.inverse_precision -= zero_digits
      end
  end
  protected :improve_inverse
  
  # Asymptotically fast method for dividing two numbers.
  def fast_divmod(other)
    # Special-case 1 so we don't have to deal with its inverse.
    if other.d.length == 1 and other.d.first == Byte.one
      return self, BigNum.zero 
    end
    
    ensure_inverse_exists other 
    
    # Division using other's multiplicative inverse.
    bn_one = BigNum.one
    loop do
      quotient = (self * other.inverse) >> other.inverse_precision
      product = other * quotient
      if product > self
        product -= other
        quotient -= bn_one
      end
      if product <= self
        remainder = self - product
        if remainder >= other
          remainder -= other
          quotient += bn_one
        end
        return [quotient, remainder] if remainder < other
      end
      improve_inverse other
    end
  end  
  
  # Modular **.
  #
  # Args:
  #    exponent:: the exponent that this number will be raised to
  #    modulus:: the modulus   
  # Returns (self ** exponent) % modulus.
  def powmod(exponent, modulus)
    multiplier = BigNum.new @d
    result = BigNum.one
    exp = BigNum.new exponent.d
    exp.normalize
    two = (Byte.one + Byte.one).lsb
    0.upto(exp.d.length - 1) do |i|
      mask = Byte.one
      0.upto(7) do |j|
        if (exp.d[i] & mask) != Byte.zero
          result = (result * multiplier) % modulus
        end
        mask = (mask * two).lsb
        multiplier = (multiplier * multiplier) % modulus
      end
    end
    result
  end
  
  # :nodoc: Debugging help: returns the BigNum formatted as "0x????...".
  def to_s
    "0x#{to_hex}"
  end
  
  # :nodoc: Debugging help: returns a representation of the instance.
  def inspect
    "#<BigNum 0x#{to_hex}, #{@d.length} digits>"
  end  
  
  # Removes all the trailing 0 (zero) digits in this number.
  # 
  # Returns self, for easy call chaining.
  def normalize
    @d.pop while @d.length > 1 and @d.last == Byte.zero
    self
  end
  
  # False if the number has at least one trailing 0 (zero) digit.
  def normalized?
    @d.length == 1 or @d.last != Byte.zero
  end


  ### SOLUTION BLOCK

  # Slow method for multiplying two numbers with good constant factors.
  def slow_mul(other)
    result = BigNum.zero(@d.length + other.d.length)
    0.upto(@d.length - 1) do |i|
      carry = Byte.zero
      0.upto(other.d.length - 1) do |j|
        word = (@d[i] * other.d[j]) + result.d[i + j].to_word + carry.to_word
        result.d[i + j] = word.lsb
        carry = word.msb
      end
      result.d[i + other.d.length] = carry
    end
    result.normalize
  end

  # Slow method for dividing two numbers with good constant factors.
  def slow_divmod(other)
    remainder = BigNum.new @d 
    divisors = [BigNum.new(other.d)]
    two = BigNum.one + BigNum.one
    while divisors.last < remainder
      divisors << (divisors.last + divisors.last).normalize
    end
    quotient = BigNum.zero
    (divisors.length - 1).downto(0) do |i|
      quotient = (quotient + quotient).normalize
      if remainder >= divisors[i]
        remainder = (remainder - divisors[i]).normalize
        quotient.d[0] |= Byte.one
      end
    end
    [quotient.normalize, remainder] 
  end 
  
  ### END SOLUTION BLOCK
end  # class BigNum