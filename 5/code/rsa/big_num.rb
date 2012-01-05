
  
class Integer
  
  def to_array
    digits = []
    digit = self.to_s(2)
    while digit.size > 8
      splice = digit[digit.size - 8, digit.size]
      int = Integer(splice)
      digits << Integer(splice)
      digit = digit[0, digit.size - 8]
    end
    if digit.size > 0
      digits << Integer(digit[0, digit.size])
    end  
    digits   
  end
  
  def powmod(exponent, modulus)
    exp_digits = exponent.to_array
    multiplier = self
    result = 1
    two = 2
    i = 0
    while i < exp_digits.size do 
      mask = 1
      bit = 0
      while bit < 8 do
        if exp_digits[i] & mask != 0
          result = (result*multiplier) % modulus
        end
        multiplier = (multiplier*multiplier) % modulus
        mask = mask * 2
        bit = bit + 1
      end
      i = i + 1
    end
    result
        
  end
end


