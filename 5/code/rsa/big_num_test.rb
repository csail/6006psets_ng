require 'test/unit'

require_relative 'big_num.rb'

class BigNumTest < Test::Unit::TestCase
  def test_equality
    assert_equal BigNum.zero(1), BigNum.zero(1)
    assert_equal BigNum.zero(1), BigNum.zero(2)
    assert_equal BigNum.one(1), BigNum.one(1)
    assert_equal BigNum.one(1), BigNum.one(2)
    assert_not_equal BigNum.zero(1), BigNum.one(1)
    assert_not_equal BigNum.zero(1), BigNum.one(2)
    assert_not_equal BigNum.zero(2), BigNum.one(1)
    assert_not_equal BigNum.zero(2), BigNum.one(2)
  end
  
  def test_strings
    assert_equal '00', BigNum.zero(1).to_hex
    assert_equal '00', BigNum.zero(3).to_hex
    assert_equal '01', BigNum.one(1).to_hex
    assert_equal '01', BigNum.one(3).to_hex
    assert_equal '0x01', BigNum.one(3).to_s
    assert_equal "BigNum.h('01', 1)", BigNum.one(1).inspect 
    assert_equal "BigNum.h('01', 3)", BigNum.one(3).inspect
    assert_equal BigNum.one, BigNum.from_hex('01')
    assert_equal BigNum.zero, BigNum.h('00')
    assert_equal 'F1E2D3C4B5', BigNum.from_hex('00F1E2D3C4B5').to_hex
  end
  
  def test_normalized
    assert BigNum.zero(1).normalized?
    assert !BigNum.zero(2).normalized?
    assert BigNum.one(1).normalized?
    assert !BigNum.one(2).normalized?
    assert BigNum.h('100').normalized?
    assert BigNum.h('0100').normalized?
    assert !BigNum.h('00101').normalized?
  end
  
  def test_normalize
    assert_equal "BigNum.h('01', 1)", BigNum.one(1).normalize.inspect
    assert_equal "BigNum.h('01', 1)", BigNum.one(3).normalize.inspect
    assert_equal "BigNum.h('00', 1)", BigNum.zero(1).normalize.inspect
    assert_equal "BigNum.h('00', 1)", BigNum.zero(3).normalize.inspect
  end

  def test_comparisons
    assert_operator BigNum.zero, :<, BigNum.one
    assert_operator BigNum.zero, :<=, BigNum.zero
    assert_operator BigNum.one, :<=, BigNum.one
    assert_operator BigNum.one, :>, BigNum.zero
    assert_operator BigNum.one, :>=, BigNum.zero
    assert_operator BigNum.zero, :>=, BigNum.zero
    assert_operator BigNum.one, :>=, BigNum.one
    
    assert_operator BigNum.h('11FF'), :< ,BigNum.h('1200')
    assert_operator BigNum.h('11FE'), :<, BigNum.h('11FF')
    assert_operator BigNum.h('10FE'), :<, BigNum.h('1100')
    assert_operator BigNum.h('FF11'), :<, BigNum.h('10000')
    assert !(BigNum.h('1200') < BigNum.h('001200'))
    assert_operator BigNum.h('11FF'), :<=, BigNum.h('1200')
    assert_operator BigNum.h('11FE'), :<=, BigNum.h('11FF')
    assert_operator BigNum.h('10FE'), :<=, BigNum.h('1100')
    assert_operator BigNum.h('FF11'), :<=, BigNum.h('10000')
    assert_operator BigNum.h('1200'), :<=, BigNum.h('001200')
  end
  
  def test_shifting
    assert_equal BigNum.h('1234567') >> 2, BigNum.h('123')
    assert_equal BigNum.h('1234567') >> 0, BigNum.h('1234567')
    assert_equal BigNum.h('1234567') >> 4, BigNum.zero()
    assert_equal BigNum.h('1234567') >> 5, BigNum.zero()
    assert_equal BigNum.h('12345') << 1, BigNum.h('1234500')
    assert_equal BigNum.h('12345') << 2, BigNum.h('123450000')
    assert_equal BigNum.h('12345') << 0, BigNum.h('12345')
    assert_equal BigNum.one << 6, BigNum.h('1000000000000')
  end
  
  def test_addition
    assert_equal BigNum.zero, BigNum.zero + BigNum.zero
    assert_equal BigNum.one, BigNum.one + BigNum.zero
    assert_equal BigNum.one, BigNum.zero + BigNum.one
    assert_equal BigNum.h('68AC'), BigNum.h('1234') + BigNum.h('5678')
    assert_equal BigNum.h('568ACE'), BigNum.h('1234') + BigNum.h('56789A')
    assert_equal BigNum.h('1000000'), BigNum.one() + BigNum.h('FFFFFF')
    assert_equal BigNum.h('FCF9F7F4'), BigNum.h('FEFDFC') + BigNum.h('FBFAF9F8')
  end
  
  def test_subtraction
    assert_equal BigNum.zero, BigNum.zero - BigNum.zero
    assert_equal BigNum.one, BigNum.one - BigNum.zero
    assert_equal BigNum.zero, BigNum.one - BigNum.one
    assert_equal BigNum.h('FF'), BigNum.zero - BigNum.one
    assert_equal BigNum.h('1357'), BigNum.h('5678') - BigNum.h('4321')
    assert_equal BigNum.h('ECA9'), BigNum.h('4321') - BigNum.h('5678')
    assert_equal BigNum.h('563579'), BigNum.h('56789A') - BigNum.h('4321')
    assert_equal BigNum.h('A9CA87'), BigNum.h('4321') - BigNum.h('56789A')
    assert_equal BigNum.h('FFA9CA87'), BigNum.h('4321') - BigNum.h('056789A')
    assert_equal BigNum.h('2'), BigNum.one - BigNum.h('FFFFFF')
    assert_equal BigNum.one(), BigNum.zero - BigNum.h('FFFFFF')
    assert_equal BigNum.h('FF000001'), BigNum.one - BigNum.h('1000000')
    assert_equal BigNum.h('FFFFFFFF'), BigNum.zero - BigNum.one(4)
  end

  def test_multiplication
    assert_equal BigNum.zero, BigNum.zero * BigNum.zero
    assert_equal BigNum.zero, BigNum.one * BigNum.zero
    assert_equal BigNum.one, BigNum.one * BigNum.one
    assert_equal BigNum.h('06260060'), BigNum.h('1234') * BigNum.h('5678')
    assert_equal BigNum.h('06260B5348'), BigNum.h('1234') * BigNum.h('56789A')
    assert_equal BigNum.h('FFFFFE000001'), BigNum.h('FFFFFF') * BigNum.h('FFFFFF')
    assert_equal BigNum.h('FAFD0318282820'), BigNum.h('FEFDFC') * BigNum.h('FBFAF9F8')
  end
  
  def test_division
    assert_equal BigNum.one, BigNum.one / BigNum.one, '1 / 1 == 1'
    assert_equal BigNum.zero, BigNum.zero / BigNum.one, '0 / 1 == 0'
    assert_equal BigNum.h('16'), BigNum.h('42') / BigNum.h('03')
    assert_equal BigNum.h('16'), BigNum.h('43') / BigNum.h('03') 
    assert_equal BigNum.h('5678'), BigNum.h('06260060') / BigNum.h('1234')
    assert_equal BigNum.h('1234'), BigNum.h('06263F29') / BigNum.h('5678')
    assert_equal BigNum.h('1234'), BigNum.h('06260FE3C9') / BigNum.h('56789A')
    assert_equal BigNum.h('FFFFFF'), BigNum.h('FFFFFE000001') / BigNum.h('FFFFFF')
    assert_equal BigNum.h('FFFFFF'), BigNum.h('FFFFFE0CFEDC') / BigNum.h('FFFFFF')
    assert_equal BigNum.h('FBFAF9F8'), BigNum.h('FAFD0318282820') / BigNum.h('FEFDFC')
    assert_equal BigNum.h('FBFAF9F8'), BigNum.h('FAFD0318C3D9EF') / BigNum.h('FEFDFC')
    assert_equal BigNum.h('8000'), BigNum.h('100000000') / BigNum.h('20000')
  end
  
  def test_modulo
    assert_equal BigNum.zero, BigNum.one % BigNum.one, '1 % 1 == 0'
    assert_equal BigNum.zero, BigNum.zero % BigNum.one, '0 % 1 == 0'
    assert_equal BigNum.zero, BigNum.h('42') % BigNum.h('03')
    assert_equal BigNum.one, BigNum.h('43') % BigNum.h('03')
    assert_equal BigNum.h('02'), BigNum.h('44') % BigNum.h('03')
    assert_equal BigNum.zero, BigNum.h('06260060') % BigNum.h('1234')
    assert_equal BigNum.h('3EC9'), BigNum.h('06263F29') % BigNum.h('5678')
    assert_equal BigNum.h('49081'), BigNum.h('06260FE3C9') % BigNum.h('56789A')
    assert_equal BigNum.zero, BigNum.h('FFFFFE000001') % BigNum.h('FFFFFF')
    assert_equal BigNum.h('CFEDB'), BigNum.h('FFFFFE0CFEDC') % BigNum.h('FFFFFF')
    assert_equal BigNum.zero, BigNum.h('FAFD0318282820') % BigNum.h('FEFDFC')
    assert_equal BigNum.h('9BB1CF'), BigNum.h('FAFD0318C3D9EF') % BigNum.h('FEFDFC')
  end
  
  def test_powmod
    modulo = BigNum.h '100000000'
    assert_equal BigNum.one, BigNum.h('42').powmod(BigNum.zero, modulo)
    assert_equal BigNum.h('42'), BigNum.h('42').powmod(BigNum.one, modulo)
    assert_equal BigNum.h('1104'), BigNum.h('42').powmod(BigNum.h('2'), modulo)
    assert_equal BigNum.h('4AA51420'), BigNum.h('42').powmod(BigNum.h('5'), modulo)
    assert_equal BigNum.h('C73043C1'), BigNum.h('41').powmod(BigNum.h('BECF'), modulo)
  end
end  # class BigNumTest
