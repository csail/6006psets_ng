#!/usr/bin/env ruby


require 'big_num.rb'
require 'rubygems'
require 'json'

class RsaKey
  
  def initialize(exponent_hex_string, modulus_hex_string)
    @e = exponent_hex_string.to_i(16)
    @n = modulus_hex_string.to_i(16)
    @size = (@n.to_s(16).length + 1) / 2
    @chunk_cache = {}
  end
  
  def raw_crypt(number)
    #Performs ECB RSA encryption / decryption
    number.powmod(@e, @n)
  end
  
  def decrypt(hex_string)
    out_chunks = []
    i = 0
    in_chunk_size = @size * 2
    out_chunk_size = (@size - 1) * 2
    while i < hex_string.size do
      in_chunk = hex_string[i, in_chunk_size]
      if @chunk_cache.has_key?(in_chunk)
        out_chunk = @chunk_cache[in_chunk]
      else
        out_chunk = self.raw_crypt(in_chunk.to_i(16)).to_s(16)
        if out_chunk.size > out_chunk_size
          #this indicates a decryption error. However, we'll truncate the
          #result, so the visualization can work.
          out_chunk = out_chunk[0, out_chunk_size]
        end
        @chunk_cache[in_chunk] = out_chunk
      end
      if out_chunk.size < out_chunk_size
        out_chunks << ('0' * (out_chunk_size - out_chunk.size))
      end
      out_chunks << out_chunk
      i = i + in_chunk_size
    end
    out_chunks.join('')
  end
end

class EncryptedImage
  #Processes an image encrypted with an RSA key.
  attr_accessor:columns
  def initialize
    @key = nil
    @encrypted_rows = []
    @rows = nil
    @columns = nil
  end
  
  def set_key(exponent_hex_string, modulus_hex_string)
    # Sets the RSA key to be used for decrypting the image
    @key = RsaKey.new(exponent_hex_string, modulus_hex_string)
  end
  
  def add_row(encrypted_row_data)
    #Append a row of encrypted pixel data to the image.
    @encrypted_rows << encrypted_row_data
  end
  
  def decrypt_image
    #Decrypts the encrypted image
    if @rows
      return
    end
    rows = []
    @encrypted_rows.each do |encrypted_row|
      row = @key.decrypt(encrypted_row)
      #if columns = 0, row_size = 0
      #otherwise row_size = 0
      row_size = @columns * 6
      if row_size
        row = row[0, row_size]
      end
      row = row.upcase()
      rows << row
    end
    @rows = rows
  end
  
  def to_line_list
    #Returns a list of strings representing the image data
    self.decrypt_image()
    @rows
  end
  
  def to_file(file)
    # Writes a textual description of the image data to a file
    # Args:
    #   file: A file object that receives the image data
    #
    self.to_line_list().each do |line|
      file.puts("#{line}\n")
    end
  end
  
  def as_json
    # A dict that obeys the JSON format, representing the image
    self.decrypt_image()
    jso = {}
    jso['image'] = {'rows' => @rows.size, 'cols' => @rows[0].size / 6, 
      'data' => @rows}
    jso['encrypted'] = {'data' => @encrypted_rows, 'rows' => @rows.size, 
      'cols' => @encrypted_rows[0].size / 6}
    jso
  end
  
  def self.from_file(file)
    # Reads an encrypted image description from a file
    # Args:
    #   file: A File object supplying the input
    # Returns a new RsaImageDecrypter instance
    #
    image = EncryptedImage.new()
    loop do
      command = file.gets.split()
      break if command[0] == 'end'
      if command[0] == 'key'
        image.set_key(command[1], command[2])
      elsif command[0] == 'sx'
        image.columns = Integer(command[1])
      elsif command[0] == 'row'
        image.add_row(command[1])
      end
    end
    image
  end
end



# Command-line controller
class Cli
  def run(args)
    image = EncryptedImage.from_file STDIN
    if ENV['TRACE'] == 'jsonp'
      STDOUT.write('onJsonp(')
      JSON.dump(image.as_json(), STDOUT)
      STDOUT.write(");\n")
    else
      image.to_file(STDOUT)
    end
  end
end

Cli.new.run(ARGV) if __FILE__ == $0

    
      
    
    
    
    
    
