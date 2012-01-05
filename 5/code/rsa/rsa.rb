#!/usr/bin/env ruby

require 'rubygems'
require 'json'

require_relative 'big_num.rb'

# Public or private RSA key.
class RsaKey
  # Initializes a key from a public or private exponent and the modulus.
  def initialize(exponent_hex_string, modulus_hex_string)
    @e = BigNum.from_hex exponent_hex_string
    @n = BigNum.from_hex modulus_hex_string
    @size = (@n.to_hex.length + 1) / 2
    @chunk_cache = {}
  end
  
  # Performs ECB RSA encryption / decryption.
  def raw_crypt(number)
    number.powmod @e, @n
  end
  
  # Decrypts a bunch of data stored as a hexadecimal string.
  # Returns a hexadecimal string with the decrypted data.
  def decrypt(hex_string)
    out_chunks = []
    i = 0
    in_chunk_size = @size * 2
    out_chunk_size = (@size - 1) * 2
    while i < hex_string.size
      in_chunk = hex_string[i, in_chunk_size]
      if @chunk_cache.has_key? in_chunk
        out_chunk = @chunk_cache[in_chunk]
      else
        out_chunk = self.raw_crypt(BigNum.from_hex(in_chunk)).to_hex
        out_chunk = out_chunk[0, out_chunk_size] if out_chunk.size > out_chunk_size
        @chunk_cache[in_chunk] = out_chunk
      end
      out_chunks << ('0' * (out_chunk_size - out_chunk.size)) if out_chunk.size < out_chunk_size
      out_chunks << out_chunk
      i += in_chunk_size
    end
    out_chunks.join ''
  end
end # class RsaKey

# Processes an image encrypted with an RSA key.
class EncryptedImage
  attr_accessor :columns
  
  def initialize
    @key = nil
    @encrypted_rows = []
    @rows = nil
    @columns = nil
  end
  
  # Sets the RSA key to be used for decrypting the image.
  def set_key(exponent_hex_string, modulus_hex_string)
    @key = RsaKey.new exponent_hex_string, modulus_hex_string
  end
  
  # Append a row of encrypted pixel data to the image.
  def add_row(encrypted_row_data)
    @encrypted_rows << encrypted_row_data
  end
  
  # Decrypts the encrypted image.
  def decrypt_image
    return if @rows
    rows = []
    @encrypted_rows.each do |encrypted_row|
      row = @key.decrypt encrypted_row
      row_size = @columns * 6
      row = row[0, row_size]
      rows << row.upcase
    end
    @rows = rows
  end
  
  # Returns a list of strings representing the image data.
  def to_line_list
    decrypt_image
    @rows
  end
  
  # Writes a textual description of the image data to a file.
  # Args:
  #   file:: A file object that receives the image data.
  def to_io(io)
    self.to_line_list.each { |line| io.write("#{line}\n") }
  end
  
  # A dict that obeys the JSON format, representing the image.
  def as_json
    self.decrypt_image
    jso = 
    {
      :image => {
        'rows' => @rows.size, 
        'cols' => @rows[0].size / 6, 
        'data' => @rows
      },
    :encrypted => {
      'data' => @encrypted_rows, 
      'rows' => @rows.size, 
      'cols' => @encrypted_rows[0].size / 6
      }
    }
  end
  
  # Reads an encrypted image description from a file.
  # Args:
  #   file:: A File object supplying the input.
  #
  # Returns a new RsaImageDecrypter instance.
  def self.from_file(file)
    image = EncryptedImage.new
    loop do
      command = file.gets.split
      case command[0]
      when 'end'
        break
      when 'key'
        image.set_key command[1], command[2]
      when 'sx'
        image.columns = command[1].to_i
      when 'row'
        image.add_row command[1]
      end
    end
    image
  end
end  # class EncryptedImage

# Command-line controller.
class Cli
  def run(args)
    image = EncryptedImage.from_file STDIN
    if ENV['TRACE'] == 'jsonp'
      STDOUT.write 'onJsonp('
      JSON.dump image.as_json, STDOUT
      STDOUT.write ");\n"
    else
      image.to_io STDOUT
    end
  end
end  # class Cli

Cli.new.run ARGV if __FILE__ == $0
