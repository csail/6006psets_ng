require 'ks_primitives_unchecked'  

class BigNum
  include Comparable
  attr_accessor :d
  
  # Creates a BigNum from a sequence of digits.
  # Args:
  #  digits:: the Bytes used to populate the BigNum
  #  size:: if set, the BigNum will only use the first 'size' elements of digits
  #  no_copy:: uses the 'digits' argument as the backing store for BigNum,
  #     if appropraite (meant for internal use inside BigNum)
  def initialize(digits, size = nil, no_copy = false)
    digits ||= []
    size ||= digits.length
    raise 'BigNums cannot hold a negative amount of digits' if size < 0
    size = 1 if size == 0
    if no_copy and digits.size == size
      @d = digits
    else
      @d = digits.dup
    end
    while @d.length < size
      @d << Byte.zero
    end
    # Used by the Newton-Raphson division code.
    @inverse = nil
    @inverse_precision = nil
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
  # Args:
  #   hex_string:: string containing the desired number in hexadecimal; the
  #                allowed digits are 0-9, A-F, a-f
  def self.from_hex(hex_string)
    digits = []
    hex_string.length.step 1, -2 do |i|
      byte_string = i == 1 ? "0#{hex_string[0,1]}" : hex_string[i - 2, 2]
      digits << Byte.from_hex(byte_string)
    end
    BigNum.new digits
  end
    
  # Shorthand for from_hex(hex_string).
  def self.h(hex_string)
    BigNum.from_hex hex_string
  end
  
  # Hexadecimal string representing this BigNum.
  # This method does not normalize the BigNum, because it is used during debugging.
  def to_hex
    start = @d.length - 1
    while start > 0 and @d[start] == Byte.zero
      start -= 1
    end
    string = ''
    start.downto(0) { |i| string += @d[i].hex }
    string
  end
  
  # == for BigNums.
  # Comparing BigNums normalizes them.
  def ==(other)
    self.normalize
    other.normalize
    @d == other.d
  end
  
  def <=>(other)
    self.normalize
    other.normalize
    if @d.length == other.d.length
      (@d.length - 1).downto 0 do |i|
        return @d[i] < other.d[i] ? -1 : 1 if @d[i] != other.d[i]
      end
      0
    else
      @d.length < other.d.length ? -1 : 1
    end
  end
  
  # This BigNum, with "digits" 0 digits appended at the end.
  # Shifting to the left multiplies the BigNum by 256^digits.
  def <<(digits)
    new_digits = Array.new digits, Byte.zero
    new_digits += @d
    BigNum.new new_digits, nil, true
  end
  
  # This BigNum, without the last "digits" digits.
  # Shifting to the left multiplies the BigNum by 256^digits.
  def >>(digits)
    return digits >= @d.length ? BigNum.zero : BigNum.new(@d[digits, @d.length - digits], nil, true)
  end
  
  # Adding numbers does not normalize them. However the result is normalized.
  def +(other)
    result = BigNum.zero 1 + [@d.length, other.d.length].max
    carry = Byte.zero
    0.upto result.d.length - 1 do |i|
      a = i < @d.length ? @d[i] + carry : carry.word
      b = i < other.d.length ? other.d[i].word : Word.zero
      word = a + b
      result.d[i] = word.lsb
      carry = word.msb
    end
    result.normalize
  end
  
  # Subtraction is done using 2s complement.
  # Subtracting numbers does not normalize them. However the result is normalized.
  def -(other)
    result = BigNum.zero [@d.length, other.d.length].max
    carry = Byte.zero
    0.upto result.d.length - 1 do |i|
      a = i < @d.length ? @d[i].word : Word.zero
      b = i < other.d.length ? other.d[i] + carry : carry.word
      word = a - b
      result.d[i] = word.lsb
      carry = a < b ? Byte.one : Byte.zero
    end
    result.normalize
  end
  
  # Multiplying numbers does not normalize them. However, the result is normalized.
  def *(other)
    return @d.length <= 64 || other.d.length <= 64 ? self.slow_mul(other) : self.fast_mul(other)
  end
  
  # Asymptotically slow method for multiplying two numbers w/ good constant factors.
  def slow_mul(other)
    c = BigNum.zero @d.length + other.d.length
    0.upto @d.length - 1 do |i|
      carry = Byte.zero
      0.upto other.d.length - 1 do |j|
        digit = @d[i] * other.d[j] + Word.from_byte(c.d[i + j]) + Word.from_byte(carry)
        c.d[i + j] = digit.lsb
        carry = digit.msb
      end
      c.d[i + other.d.length] = carry
    end
    c
  end
  
  # Asymptotically fast method for multiplying two numbers.
  def fast_mul(other)
    in_digits = [@d.length, other.d.length].max
    if in_digits == 1
      product = @d[0] * other.d[0]
      return BigNum.new [product.lsb, product.msb], 2, true
    end
    split = in_digits/2
    self_low = BigNum.new @d[0, split], nil, true
    self_high = BigNum.new @d[split, @d.length - split], nil, true
    other_low = BigNum.new other.d[0, split], nil, true
    other_high = BigNum.new other.d[split, other.d.length - split], nil, true
    
    result_high_high = self_high * other_high
    result_low = self_low * other_low
    result_high = (self_low + self_high) * (other_low + other_high) - (result_high_high + result_low)
    ((result_high_high << (2 * split)) + (result_high << split) + result_low).normalize
  end
  
  # Dividing numbers normalizes them. The result is also normalized.
  def /(other)
    self.divmod(other)[0]
  end
  
  # Multiplying numbers does not normalize them. However, the result is normalized.
  def %(other)
    self.divmod(other)[1]
  end
  
  # divmod for BigNums
  # Dividing numbers normalizes them. The result is also normalized.
  def divmod(other)
    self.normalize
    other.normalize
    return self.slow_divmod(other) if @d.length <= 256 || other.d.length <= 256
    self.fast_divmod(other)
  end
  
  # Asymptotically slow method for dividing two numbers w/ good constant factors.
  def slow_divmod(other)
    return self, BigNum.zero if other.d.length == 1 && other.d[0] == Byte.one
    n = [@d.length, other.d.length].max
    q = BigNum.zero n
    r = BigNum.new @d
    s = []
    s << BigNum.new(other.d, n)
    i = 0
    loop do
      i += 1
      s << s[i - 1] + s[i - 1]
      break if s[i] > self
    end
    
    i.downto 0 do |j|
      q += q
      if r >= s[j]
        r -= s[j]
        q += BigNum.one
      end
    end
    return q, r
  end
  
  # Asymptotically fast method for dividing two numbers.
  def fast_divmod(other)
    return self, BigNum.zero if other.d.length == 1 and other.d[0] == Byte.one
    if !other.inverse
      base = Word.from_bytes Byte.one, Byte.zero
      msb_plus = (other.d[-1] + Byte.one).lsb
      if msb_plus == Byte.zero
        msb_inverse = (base - Word.one).lsb
        other.inverse_precision = other.d.length + 1
      else
        msb_inverse = base / msb_plus
        other.inverse_precision = other.d.length
      end
      other.inverse = BigNum.new [msb_inverse], 1, true
    end
    bn_one = BigNum.one
    # Division using other's multiplicative inverse.
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
        return quotient, remainder if remainder < other
      end
      # other needs a better multiplicative inverse approximation     
      other.improve_inverse
    end
  end
  
  protected
  def improve_inverse
    old_inverse = @inverse
    old_precision = @inverse_precision
    @inverse = ((old_inverse + old_inverse) << old_pecision) - (self * old_inverse * old_inverse)
    @inverse.normalize
    @inverse_precision *= 2
    zero_digits = 0
    while @inverse.d[zero_digits] == Byte.zero
      zero_digits += 1
    end
    if zero_digits > 0
      @inverse = @inverse >> zero_digits
      @inverse_precision -= zero_digits
    end
  end
  
  def inverse
    @inverse
  end
  
  def inverse_precision
    @inverse_precision
  end
  
  # Modular ^
  #
  # Args:
  #   exponent:: the exponent that this number will be raised to
  #   modulus:: the modulus
  #
  # Returns (self ^ exponent) mod modulus.
  public
  def powmod(exponent, modulus)
    multiplier = BigNum.new @d
    result = BigNum.one
    exp = BigNum.new exponent.d
    exp.normalize
    two = (Byte.one + Byte.one).lsb
    0.upto exp.d.length - 1 do |i|
      mask = Byte.one
      0.upto 7 do |j|
        result = (result * multiplier) % modulus if (exp.d[i] & mask) != Byte.zero
        mask = (mask * two).lsb
        multiplier = (multiplier * multiplier) % modulus
      end
    end
    result
  end
  
  # Debugging help: returns the BigNum formatted as "0x????...".
  def to_s
    "0x#{self.to_hex}"
  end
  
  # Debugging help: returns an expression that can create this BigNum.
  def inspect
    "BigNum.h('#{self.to_hex}', #{@d.length.to_s})"
  end
  
  # Removes all the trailing 0 (zero) digits in this number.
  # Returns self, for easy call chaining.
  def normalize
    while @d.length > 1 and @d[-1] == Byte.zero
      @d.pop
    end
    self
  end
  
  # False if the number has at least one trailing 0 (zero) digit.
  def is_normalized
    @d.length == 1 || @d[-1] != Byte.zero
  end
end # class BigNum
