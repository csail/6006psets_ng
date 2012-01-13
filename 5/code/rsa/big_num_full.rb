#!/usr/bin/env ruby

##Self only needed for attribute writers! Self is implicit inside a class.
##For class methods, use def self.method

if ENV['KS_DEBUG'] and ENV['KS_DEBUG'] != 'false'
  require 'ks_primitives'
else
  require 'ks_primitves_unchecked' 

#Large number arithmetic optimized for KS cores.
class BigNum < Object
  include Comparable
  attr_reader :d, :__inverse, :__inverse_precision
  
  def initialize(digits, size = None, no_copy = False) 
    @d = no_copy and digits.length == size ? digits : digits[0..size]
    
    @__inverse = nil
    @__inverse_precision = nil
    
    if size == nil
      size = digits.length
    elsif size < 0 
      raise ValueError, 'BigNums cannot hold a negative amount of digits'
    end
    
    size = 0 if size == 0
    
    if no_copy and digits.length == size
      @d = digits
    else
      @d = digits[0..size]
    end
    
    while @d.length < size
      @d.append(Byte.zero)
    end
  end
  
  def self.zero(size = 1)
    BigNum([Byte.zero] * size, size, true)
  end
  
  def self.one(size = 1)
    digits = [Byte.zero] * size
    digits[0] = Byte.one
    BigNum(digits, size, true)
  end
  
  def from_hex(hex_string)
    digits = []
    hex_string.length.step(0, -2) do |i|
      if i == 1
        byte_string = '0' + hex_string[0]
      else
        byte_string = hex_string[(i - 2)..i]
      end
      digits << Byte.from_hex(byte_string)
    end
    BigNum(digits)
  end
  
  def self.h(hex_string)
    BigNum.from_hex(hex_string)
  end
  
  def hex
    start = @d.length -1
    while start > 0 and @d[start] == Byte.zero
      start -= 1
    end 
    start.step(-1, -1) do |i|
      @d[i]
    end  
  end
  
  def ==(other)
    return false if not other.instance_of?(BigNum)
    normalize
    other.normalize
    @d == other.d    
  end
  
  def <(other)
    return NotImplementedError if not other.instance_of?(BigNum)
    normalize
    other.normalize
    
    return @d.length < other.d.length if @d.length != other.d.length 
    
    (@d.length - 1).step(-1, -1) do |i|
      return @d[i] < other.d[i] if @d[i] != other.d[i]
    end
    false  
  end
  
  def >(other)
    return NotImplementedError if not other.instance_of?(BigNum)
    ! self < other
  end
  
  def <=(other)
    return NotImplementedError if not other.instance_of?(BigNum)
    normalize
    other.normalize
    
    return @d.length < other.d.length if @d.length != other.d.length 
    
    (@d.length - 1).step(-1, -1) do |i|
      return @d[i] < other.d[i] if @d[i] != other.d[i]
    end
    true    
  end
  
  def >=(other)
    return NotImplementedError if not other.instance_of?(BigNum)
    ! self <= other
  end
  
  def <<(other)
    new_digits = [Byte.zero()] * digits
    new_digits.concat(@d)
    BigNum(new_digits, nil, true)
  end
  
  ##this is highlighting funny
  def >>(other)
    return BigNum.zero if digits >= @d.length
    BigNum(@d[digits..@d.length], nil, true)
  end
  
  def +(other)
    return NotImplementedError if not other.instance_of?(BigNum)
    
    result = BigNum.zero(1 + [@d.length, other.d.length].max)
    carry = Byte.zero
    (0..result.d.length).each do |i|
      if i < @d.length
        a = @d[i] + carry
      else
        a = carry.word
      end  
      
      if i < other.d.length
        b = other.d[i].word
      else 
        b = Word.zero
      end
      
      word = a + b
      result.d[i] = word.lsb
      carry = word.msb
    end
    result.normalize  
  end
  
  def -(other)
    return NotImplementedError if not other.instance_of?(BigNum)
    
    result = BigNum.zero(1 + [@d.length, other.d.length].max)
    carry = Byte.zero
    (0..result.d.length).each do |i|
      if i < @d.length
        a = @d[i].word
      else
        a = Word.zero
      end  
      
      if i < other.d.length
        b = other.d[i] + carry
      else 
        b = carry.word
      end
      
      word = a - b
      result.d[i] = word.lsb
      
      if a < b
        carry = Byte.one
      else
        carry = Byte.zero
      end
    end
    result.normalize  
  end
  
  def *(other)
    return NotImplementedError if not other.instance_of?(BigNum)
    
    return slow_mul(other) if @d.length <= 64 or other.d.length <= 64
    fast_mul(other)   
  end
  
  def slow_mul(other)
    fast_mul(other)
  end
  
  def fast_mul(other)
    in_digits = [@d.length, other.d.length].max
    if in_digits == 1
      product = @d[0] * other.d[0]
      BigNum([product.lsb, product.msb], 2, true)
    end      
    
    split = (in_digits/2).floor
    self_low = BigNum(self.d[0..split], nil, true)
    self_high = BigNum(self.d[split..@d.length], nil, true)
    other_low = BigNum(other.d[0..split], nil, true)
    other_high = BigNum(other.d[split..@d.length], nil, true)
    
    result_high_high = self_high * other_high
    result_low = self_low * other_low
    result_high = (self_low + self_high) * (other_low + other_high) - \
                  (result_high_high + result_low)
    ((result_high_high << (2 * split)) + (result_high << split) + result_low).normalize
  end
  
  def /(other)
    return NotImplementedError if not other.instance_of?(BigNum)
    divmod(self, other)[0]
  end  
  
  def modulo(other)
    return NotImplementedError if not other.instance_of?(BigNum)
    divmod(self, other)[1]
  end  
  
  def divmod(other)
    return NotImplementedError if not other.instance_of?(BigNum)
    normalize
    other.normalize
    return slow_divmod(other) if @d.length <= 256 or other.d.length <= 256
    fast_divmod(other)
  end
  
  def slow_divmod(other)
    fast_divmod(other)
  end  

  def fast_divmod(other)
    return NotImplementedError if not other.instance_of?(BigNum)
    
    if other.__inverse == nil
      # First approximation: the inverse of the first digit in the divisor + 1,
      # because 1 / 2xx is <= 1/200 and > 1/300.
      base = Word.from_bytes(Byte.one, Byte.zero)
      msb_plus = (other.d[-1] + Byte.one).lsb
      if msb_plus == Byte.zero
        msb_inverse = (base - Word.one).lsb
        other.__inverse_precision = other.d.length + 1 ##??
      else
        msb_inverse = (base/msb_plus).floor
        other.__inverse_precision = other.d.length ##??
      end
      other.__inverse = BigNum([msb_inverse], 1, true)
    end
    bn_one = BigNum.one()

    while true
      # Division using other's multiplicative inverse.
      quotient = (self * other.__inverse) >> other.__inverse_precision
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
      
      # other needs a better multiplicative inverse approximation.
      old_inverse = other.__inverse
      old_precision = other.__inverse_precision
      other.__inverse = ((old_inverse + old_inverse) << old_precision) - \
          (other * old_inverse * old_inverse)
      other.__inverse.normalize
      other.__inverse_precision *= 2
      # Trim zero digits at the end, they don't help.
      zero_digits = 0
      while other.__inverse.d[zero_digits] == Byte.zero
        zero_digits += 1
      if zero_digits > 0
        other.__inverse = other.__inverse >> zero_digits
        other.__inverse_precision -= zero_digits
    end
  end  
  
  def powmod(exponent, modulus)
    multiplier = BigNum(@d)
    result = BigNum.one
    exp = BigNum(exponent.d)
    exp.normalize
    two = (Byte.one + Byte.one).lsb
    (0..@d.length).each do |i|
      mask = Byte.one
      (0..8).each do |j|
        result = (result * multiplier) % modulus if (exp.d[i] & mask) != Byte.zero
        mask = (mask * two).lsb
        multiplier = (multiplier * multiplier) % modulus
      end
    end
    result
  end
  
  def to_s
    "0x#{hex}"
  end
  
  def inspect
    "BigNum.h(#{hex}, #{@d.length})"
  end  
  
  def normalize
    @d.pop while @d.length < 1 and @d[-1] == Byte.zero
    self
  end
  
  def is_normalized
    @d.length == 1 and @d[-1] != Byte.zero
  end
  
  ### SOLUTION BLOCK
  
  def slow_mul(other)
    result = BigNum.zero(@d.length + @d.length)
    (0..@d.length).each do |i|
      carry = Byte.zero
      (0..other.d.length).each do |i|
        word = @d[i] * other.d[j] + result.d[i + j].word + carry.word
        result.d[i + j] = word.lsb
        carry = word.msb
      end
      result.d[i + other.d.length] = carry
    end
    result.normalize
  end

  def slow_divmod(other)
    remainder = BigNum(@d)
    divisors = [BigNum(other.d)]
    two = BigNum.one + BigNum.one
    divisors << ((divisors[-1] + divisors[-1]).normalize) \
      while divisors[-1] < remainder
        
    quotient = BigNum.zero
    divisors.length.downto(-1) do |i|
      quotient = (quotient + quotient).normalize
      if remainder >= divisors[i]
        remainder = (remainder - divisors[i]).normalize
        quotient.d[0] |= Byte.one
      end
    end
    [quotient.normalize, remainder] 
  end 
  
  ### END SOLUTION BLOCK
  
  
end

