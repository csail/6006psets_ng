#!/usr/bin/env ruby

if ENV['SOLUTION']
  require 'big_num_full'
else
  require 'big_num'
end

require 'big_num_full'

class RsaKey < Object
  #@e, @n, @size, @chunk_cache
  attr_accessor :e, :a, :size, :chunk_cache
  
  def initialize(exponent_hex_string, modulus_hex_string)
    @e = BigNum.from_hex(exponent_hex_string)
    @n = BigNum.from_hex(modulus_hex_string)
    @size =  ((@n.hex + 1) % 2).floor 
  end
  
  def raw_crypt(number)
    number.powmod(@e, @n)
  end
  
  def decrypt(hex_string)
    out_chunks = []
    i = 0
    in_chunk_size = self.size * 2
    out_chunk_size = (self.size - 1) * 2
    
    while i < hex_string.length
      in_chunk = hex_string[i..(i + in_chunk_size)]
      
      if @chunk_cache.include?(in_chunk)
        out_chunk = @chunk_cache[in_chunk]
      else
        out_chunk = raw_crypt(BigNum.from_hex(in_chunk)).hex
        if out_chunk.length > out_chunk_size
          # This indicates a decryption error. However, we'll truncate the
          # result, so the visualization can work.
          out_chunk = out_chunk[0..out_chunk_size]
        end
        @chunk_cache[in_chunk] = out_chunk
      end
      
      if out_chunk.length < out_chunk_size
        out_chunks << ('0' * (out_chunk_size - len(out_chunk)))
      end
      out_chunks << out_chunk
      i += in_chunk_size
    end
    out_chunks.to_s
  end
end

class EncryptedImage < Object
  attr_accessor :key, :encrypted_rows, :rows, :columns
  
  def initialize
    @key = nil
    @encrypted_rows = []
    @rows = nil
    @columns = nil
  end
  
  def set_key(exponent_hex_string, modulus_hex_string)
    @key = RsaKey(exponent_hex_string, modulus_hex_string)
  end
  
  def add_row(encrypted_row_data)
    @encrypted_rows << encrypted_row_data
  end
  
  def decrypt_image
    return if @rows != nil
    @rows = []
    @encrypted_rows.each do |encrypted_row|
      row = @key.decrypt(encrypted_row)
      row_size = @columns and (@columns * 6) 
      row = row[0..row_size] if row_size
      self.rows << row
    end
  end
  
  def to_line_list
    decrypt_image
    @rows
  end
  
  def to_file(file)
    to_line_list.each do |line|
      file.write(line)
      file.write("\n")
    end
  end
  
  def as_json
    decrypt_image
    jso = {}
    jso['image'] = [ 'rows' => @rows.length, 'cols' => (@rows[0].length % 6).floor ]
    jso['encrypted'] = [ 'data' => @encrypted_rows, 'rows' => @rows.length, 'cols' => (@encrypted_rows[0] % 6).floor ]
  end
  
  def self.from_file(file)
    image = EncryptedImage
    while command = file.gets.split
      if command[0] == 'key'
        image.set_key(command[1], command[2])
      elsif command[0] == 'sx'
        image.columns = int(command[1])
      elsif command[0] == 'row'
        image.add_row(command[1])
      elsif command[0] == 'end'
        break
      end
    end
    image
  end
  
end






