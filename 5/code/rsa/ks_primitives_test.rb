#!/usr/bin/env ruby
require 'test/unit'

if ENV['KS_DEBUG'] and ENV['KS_DEBUG'] != 'false'
  require './ks_primitives.rb'
else
  require './ks_primitives.rb'  # TODO: rename to './ks_primitives_unchecked.rb'
end

class TestWordsFromString < Test::Unit::TestCase
  def test_equality
    assert_equal Byte.zero, Byte.zero
    assert_equal Byte.one, Byte.one
    assert_not_equal Byte.zero, Byte.one
    assert_not_equal Byte.one, Byte.zero
  end

  def test_comparisons
    assert_operator Byte.one, :>, Byte.zero
    assert !(Byte.zero > Byte.one)
    assert_operator Byte.one, :>=, Byte.zero
    assert_operator Byte.one, :>=, Byte.one
    assert_operator Byte.zero, :<, Byte.one
    assert !(Byte.one < Byte.zero)
    assert_operator Byte.zero, :<=, Byte.one
    assert_operator Byte.one, :<=, Byte.one
  end
    
  def test_strings
    assert_equal '01', Byte.one.to_hex
    assert_equal '0x01', Byte.one.to_s
    assert_equal "#<Byte 0x01>", Byte.one.inspect
    assert_equal Byte.one, Byte.from_hex('01')
    assert_equal Byte.zero, Byte.h('00')
    assert_equal 'F1', Byte.h('F1').to_hex
  end
    
  def test_addition
    assert_equal Word.zero, Byte.zero + Byte.zero
    assert_equal Word.one, Byte.one + Byte.zero
    assert_equal Word.one, Byte.zero + Byte.one
    assert_equal Word.h('00FF'), Byte.h('5A') + Byte.h('A5')
    assert_equal Word.h('01FE'), Byte.h('FF') + Byte.h('FF')
  end
  
  def test_subtraction
    assert_equal Word.zero, Byte.zero - Byte.zero
    assert_equal Word.one, Byte.one - Byte.zero
    assert_equal Word.zero, Byte.one - Byte.one
    assert_equal Word.h('004B'), Byte.h('A5') - Byte.h('5A')
    assert_equal Word.h('FFB5'), Byte.h('5A') - Byte.h('A5')
    assert_equal Word.h('0000'), Byte.h('FF') - Byte.h('FF')
  end

  def test_multiplication
    assert_equal Word.zero, Byte.zero * Byte.zero
    assert_equal Word.zero, Byte.zero * Byte.one
    assert_equal Word.one, Byte.one * Byte.one
    assert_equal Word.h('3A02'), Byte.h('A5') * Byte.h('5A')
    assert_equal Word.h('FE01'), Byte.h('FF') * Byte.h('FF')
  end

  def test_division
    assert_equal Byte.one, Byte.one / Byte.one, '1 / 1 == 1'
    assert_equal Byte.zero, Byte.zero / Byte.one, '0 / 1 == 0'
    assert_equal Byte.h('16'), Byte.h('42') / Byte.h('03')
    assert_equal Byte.h('16'), Byte.h('43') / Byte.h('03')    
  end

  def test_modulo
    assert_equal Byte.zero, Byte.one % Byte.one
    assert_equal Byte.zero, Byte.zero % Byte.one
    assert_equal Byte.zero, Byte.h('42') % Byte.h('03')
    assert_equal Byte.one, Byte.h('43') % Byte.h('03')
    assert_equal Byte.h('02'), Byte.h('44') % Byte.h('03')    
  end

  def test_and
    assert_equal Byte.one, Byte.one & Byte.one
    assert_equal Byte.zero, Byte.one & Byte.zero
    assert_equal Byte.zero, Byte.zero & Byte.zero
    assert_equal Byte.h('4A'), Byte.h('5F') & Byte.h('6A')
  end

  def test_or
    assert_equal Byte.one, Byte.one | Byte.one
    assert_equal Byte.one, Byte.one | Byte.zero
    assert_equal Byte.zero, Byte.zero | Byte.zero
    assert_equal Byte.h('7F'), Byte.h('5F') | Byte.h('6A')
  end

  def test_xor
    assert_equal Byte.zero, Byte.one ^ Byte.one
    assert_equal Byte.one, Byte.one ^ Byte.zero
    assert_equal Byte.zero, Byte.zero ^ Byte.zero
    assert_equal Byte.h('35'), Byte.h('5F') ^ Byte.h('6A')
  end
end  # class Test::Unit::TestCase::TestWordsFromString


class WordTest < Test::Unit::TestCase
  def test_equality
    assert_equal Word.zero, Word.zero
    assert_equal Word.one, Word.one
    assert_not_equal Word.zero, Word.one
    assert_not_equal Word.one, Word.zero
  end

  def test_equality_vs_byte
    assert_not_equal Word.zero, Byte.zero
    assert_not_equal Word.one, Byte.one
  end

  def test_comparisons
    assert_operator Word.one, :> ,Word.zero
    assert !(Word.zero > Word.one)
    assert_operator Word.one, :>= , Word.zero
    assert_operator Word.one, :>= , Word.one
    assert_operator Word.zero, :< , Word.one
    assert !(Word.one < Word.zero)
    assert_operator Word.zero, :<=, Word.one
    assert_operator Word.one, :<=, Word.one
  end
    
  def test_strings
    assert_equal '0001', Word.one.to_hex
    assert_equal '0x0001', Word.one.to_s
    assert_equal "#<Word 0x0001>", Word.one.inspect
    assert_equal Word.one, Word.from_hex('0001')
    assert_equal Word.zero, Word.h('0000')
    assert_equal 'FE12', Word.h('FE12').to_hex
  end
    
  def test_addition
    assert_equal Word.zero, Word.zero + Word.zero
    assert_equal Word.one, Word.one + Word.zero
    assert_equal Word.one, Word.zero + Word.one
    assert_equal Word.h('68AC'), Word.h('1234') + Word.h('5678')
    assert_equal Word.h('FFFE'), Word.h('FFFF') + Word.h('FFFF')
  end

  def test_subtraction
    assert_equal Word.zero, Word.zero - Word.zero
    assert_equal Word.one, Word.one - Word.zero
    assert_equal Word.zero, Word.one - Word.one
    assert_equal Word.h('FFFF'), Word.zero - Word.one
    assert_equal Word.h('1357'), Word.h('5678') - Word.h('4321')
    assert_equal Word.h('ECA9'), Word.h('4321') - Word.h('5678')
  end

  def test_division
    assert_equal Byte.one, Word.one / Byte.one
    assert_equal Byte.zero, Word.zero / Byte.one
    assert_equal Byte.h('C7'), Word.h('4321') / Byte.h('56')
    assert_equal Byte.h('5A'), Word.h('3A02') / Byte.h('A5')
    assert_equal Byte.h('FF'), Word.h('FE01') / Byte.h('FF')
    assert_equal Byte.h('21'), Word.h('4321') / Byte.one
  end

  def test_modulo
    assert_equal Byte.zero, Word.one % Byte.one
    assert_equal Byte.zero, Word.zero % Byte.one
    assert_equal Byte.h('47'), Word.h('4321') % Byte.h('56')
    assert_equal Byte.zero, Word.h('3A02') % Byte.h('A5')
    assert_equal Byte.zero, Word.h('4321') % Byte.one
    assert_equal Byte.h('FE'), Word.h('FEFF') % Byte.h('FF')
  end

  def test_and
    assert_equal Word.one, Word.one & Word.one
    assert_equal Word.zero, Word.one & Word.zero
    assert_equal Word.zero, Word.zero & Word.zero
    assert_equal Word.h('104A'), Word.h('125F') & Word.h('346A')
  end

  def test_or
    assert_equal Word.one, Word.one | Word.one
    assert_equal Word.one, Word.one | Word.zero
    assert_equal Word.zero, Word.zero | Word.zero
    assert_equal Word.h('367F'), Word.h('125F') | Word.h('346A')
  end

  def test_xor
    assert_equal Word.zero, Word.one ^ Word.one
    assert_equal Word.one, Word.one ^ Word.zero
    assert_equal Word.zero, Word.zero ^ Word.zero
    assert_equal Word.h('2635'), Word.h('125F') ^ Word.h('346A')
  end
end  # class Test::Unit::TestCase::WordTest

