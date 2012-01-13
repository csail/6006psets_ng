#!/usr/bin/env ruby
require 'test/unit'

if ENV['KS_DEBUG'] and ENV['KS_DEBUG'] != 'false'
  require 'ks_primitives'
else
  require 'ks_primitves_unchecked' 
end

class TestWordsFromString < Test::Unit::TestCase
  def test_equality
    assert_equal(Byte.zero, Byte.zero, '0 == 0')
    assert_equal(Byte.one, Byte.one, '0 == 0')
    assert_not_equal(Byte.zero, Byte.one, '0 != 1')
    assert_not_equal(Byte.one, Byte.zero, '1 != 0')
  end

  def test_comparisons
    assert_operator(Byte.one, :>, Byte.zero, '1 > 0')
    assert_operator(Byte.zero, :>, Byte.one, 'not (0 > 1)')
    assert_operator(Byte.one, :>=, Byte.zero, '1 >= 0')
    assert_operator(Byte.one, :>=, Byte.one, '1 >= 1')
    assert_operator(Byte.zero, :<, Byte.one, '0 < 1')
    assert_operator(Byte.one, :<, Byte.zero, 'not (0 < 1)')
    assert_operator(Byte.zero, :<=, Byte.one, '0 <= 1')
    assert_operator(Byte.one, :<=, Byte.one, '1 <= 1')
  end
    
  def test_strings
    assert_equal(Byte.one.hex, '01')
    assert_equal(Byte.one.to_a, '0x01')
    assert_equal(Byte.one.inspect, "Byte.h('01')")
    assert_equal(Byte.from_hex('01'), Byte.one)
    assert_equal(Byte.h('00'), Byte.zero)
    assert_equal(Byte.h('F1').hex, 'F1')
  end
    
  def test_addition
    assert_equal(Byte.zero + Byte.zero, Word.zero, '0 + 0 == 0')
    assert_equal(Byte.one + Byte.zero, Word.one, '1 + 0 == 1')
    assert_equal(Byte.zero + Byte.one, Word.one, '0 + 1 == 1')
    assert_equal(Byte.h('5A') + Byte.h('A5'), Word.h('00FF'))
    assert_equal(Byte.h('FF') + Byte.h('FF'), Word.h('01FE'))
  end
  
  def test_subtraction
    assert_equal(Byte.zero - Byte.zero, Word.zero, '0 - 0 == 0')
    assert_equal(Byte.one - Byte.zero, Word.one, '1 - 0 == 1')
    assert_equal(Byte.one - Byte.one, Word.zero, '1 - 1 == 0')
    assert_equal(Byte.h('A5') - Byte.h('5A'), Word.h('004B'))
    assert_equal(Byte.h('5A') - Byte.h('A5'), Word.h('FFB5'))
    assert_equal(Byte.h('FF') - Byte.h('FF'), Word.h('0000'))
  end

  def test_multiplication
    assert_equal(Byte.zero * Byte.zero, Word.zero, '0 * 0 == 0')
    assert_equal(Byte.zero * Byte.one, Word.zero, '0 * 1 == 0')
    assert_equal(Byte.one * Byte.one, Word.one, '1 * 1 == 0')
    assert_equal(Byte.h('A5') * Byte.h('5A'), Word.h('3A02'))
    assert_equal(Byte.h('FF') * Byte.h('FF'), Word.h('FE01'))
  end

  def test_division
    assert_equal(Byte.one / Byte.one, Byte.one, '1 / 1 == 1')
    assert_equal(Byte.zero / Byte.one, Byte.zero, '0 / 1 == 0')
    assert_equal(Byte.h('42') / Byte.h('03'), Byte.h('16'))
    assert_equal(Byte.h('43') / Byte.h('03'), Byte.h('16'))    
  end

  def test_modulo
    assert_equal(Byte.one % Byte.one, Byte.zero, '1 % 1 == 0')
    assert_equal(Byte.zero % Byte.one, Byte.zero, '0 % 1 == 0')
    assert_equal(Byte.h('42') % Byte.h('03'), Byte.zero)
    assert_equal(Byte.h('43') % Byte.h('03'), Byte.one)    
    assert_equal(Byte.h('44') % Byte.h('03'), Byte.h('02'))    
  end

  def test_and
    assert_equal(Byte.one & Byte.one, Byte.one, '1 & 1 == 1')
    assert_equal(Byte.one & Byte.zero, Byte.zero, '1 & 0 == 0')
    assert_equal(Byte.zero & Byte.zero, Byte.zero, '0 & 0 == 0')
    assert_equal(Byte.h('5F') & Byte.h('6A'), Byte.h('4A'))
  end

  def test_or
    assert_equal(Byte.one | Byte.one, Byte.one, '1 | 1 == 1')
    assert_equal(Byte.one | Byte.zero, Byte.one, '1 | 0 == 1')
    assert_equal(Byte.zero | Byte.zero, Byte.zero, '0 | 0 == 0')
    assert_equal(Byte.h('5F') | Byte.h('6A'), Byte.h('7F'))
  end

  def test_xor
    assert_equal(Byte.one ^ Byte.one, Byte.zero, '1 ^ 1 == 0')
    assert_equal(Byte.one ^ Byte.zero, Byte.one, '1 ^ 0 == 1')
    assert_equal(Byte.zero ^ Byte.zero, Byte.zero, '0 ^ 0 == 0')
    assert_equal(Byte.h('5F') ^ Byte.h('6A'), Byte.h('35'))
  end
end

class WordTest  < Test::Unit::TestCase
  def test_equality
    assert_equal(Word.zero, Word.zero, '0 == 0')
    assert_equal(Word.one, Word.one, '0 == 0')
    assert_not_equal(Word.zero, Word.one, '0 != 1')
    assert_not_equal(Word.one, Word.zero, '1 != 0')
  end

  def test_equality_vs_byte
    assert_not_equal(Word.zero, Byte.zero, '(Word)0 != (Byte)0')
    assert_not_equal(Word.one, Byte.one, '(Word)1 != (Byte)1')
  end

  def test_comparisons
    assert_operator(Word.one, :> ,Word.zero, '1 > 0')
    assert_operator(Word.zero, :> , Word.one, 'not (0 > 1)')
    assert_operator(Word.one, :>= , Word.zero, '1 >= 0')
    assert_operator(Word.one, :>= , Word.one, '1 >= 1')
    assert_operator(Word.zero, :< , Word.one, '0 < 1')
    assert_operator(Word.one, :< , Word.zero, 'not (0 < 1)')
    assert_operator(Word.zero, :<=, Word.one, '0 <= 1')
    assert_operator(Word.one, :<=, Word.one, '1 <= 1')
  end
    
  def test_strings
    assert_equal(Word.one.hex, '0001')
    assert_equal(Word.one.to_s, '0x0001')
    assert_equal(Word.one.inspect, "Word.h('0001')")
    assert_equal(Word.from_hex('0001'), Word.one)
    assert_equal(Word.h('0000'), Word.zero)
    assert_equal(Word.h('FE12').hex(), 'FE12')
  end
    
  def test_addition
    assert_equal(Word.zero + Word.zero, Word.zero, '0 + 0 == 0')
    assert_equal(Word.one + Word.zero, Word.one, '1 + 0 == 1')
    assert_equal(Word.zero + Word.one, Word.one, '0 + 1 == 1')
    assert_equal(Word.h('1234') + Word.h('5678'), Word.h('68AC'))
    assert_equal(Word.h('FFFF') + Word.h('FFFF'), Word.h('FFFE'))
  end

  def test_subtraction
    assert_equal(Word.zero - Word.zero, Word.zero, '0 - 0 == 0')
    assert_equal(Word.one - Word.zero, Word.one, '1 - 0 == 1')
    assert_equal(Word.one - Word.one, Word.zero, '1 - 1 == 0')
    assert_equal(Word.zero - Word.one, Word.h('FFFF'))
    assert_equal(Word.h('5678') - Word.h('4321'), Word.h('1357'))
    assert_equal(Word.h('4321') - Word.h('5678'), Word.h('ECA9'))
  end

  def test_division
    assert_equal(Word.one / Byte.one, Byte.one, '1 / 1 == 1')
    assert_equal(Word.zero / Byte.one, Byte.zero, '0 / 1 == 0')
    assert_equal(Word.h('4321') / Byte.h('56'), Byte.h('C7'))
    assert_equal(Word.h('3A02') / Byte.h('A5'), Byte.h('5A'))
    assert_equal(Word.h('FE01') / Byte.h('FF'), Byte.h('FF'))
    assert_equal(Word.h('4321') / Byte.one, Byte.h('21'))
  end

  def test_modulo
    assert_equal(Word.one % Byte.one, Byte.zero, '1 % 1 == 0')
    assert_equal(Word.zero % Byte.one, Byte.zero, '0 % 1 == 0')
    assert_equal(Word.h('4321') % Byte.h('56'), Byte.h('47'))
    assert_equal(Word.h('3A02') % Byte.h('A5'), Byte.zero)    
    assert_equal(Word.h('4321') % Byte.one, Byte.zero)    
    assert_equal(Word.h('FEFF') % Byte.h('FF'), Byte.h('FE'))
  end

  def test_and
    assert_equal(Word.one & Word.one, Word.one, '1 & 1 == 1')
    assert_equal(Word.one & Word.zero, Word.zero, '1 & 0 == 0')
    assert_equal(Word.zero & Word.zero, Word.zero, '0 & 0 == 0')
    assert_equal(Word.h('125F') & Word.h('346A'), Word.h('104A'))
  end

  def test_or
    assert_equal(Word.one | Word.one, Word.one, '1 | 1 == 1')
    assert_equal(Word.one | Word.zero, Word.one, '1 | 0 == 1')
    assert_equal(Word.zero | Word.zero, Word.zero, '0 | 0 == 0')
    assert_equal(Word.h('125F') | Word.h('346A'), Word.h('367F'))
  end

  def test_xor
    assert_equal(Word.one ^ Word.one, Word.zero, '1 ^ 1 == 0')
    assert_equal(Word.one ^ Word.zero, Word.one, '1 ^ 0 == 1')
    assert_equal(Word.zero ^ Word.zero, Word.zero, '0 ^ 0 == 0')
    assert_equal(Word.h('125F') ^ Word.h('346A'), Word.h('2635'))
  end
end

#if __name__ == '__main__':
#  unittest.main()
