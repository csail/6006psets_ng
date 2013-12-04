#!/usr/bin/env ruby

if ENV['SOLUTION']
  require './big_num_full.rb'
else
  require './big_num_full.rb'  # TODO: rename to './big_num.rb'
end

# Public or private RSA key.
class RsaKey < Object
  attr_accessor :e, :a, :size, :chunk_cache
  
  # Initializes a key from a public or private exponent and the modulus.
  def initialize(exponent_hex_string, modulus_hex_string)
    @e = BigNum.from_hex exponent_hex_string
    @n = BigNum.from_hex modulus_hex_string
    @size =  (@n.to_hex.length + 1) / 2
    @chunk_cache = {}
  end
  
  # Performs ECB RSA encryption / decryption.
  def raw_crypt(number) 
    number.powmod @e, @n
  end
  
  # Decrypts a bunch of data stored as a hexadecimal string.
  #
  # Returns a hexadecimal string with the decrypted data.
  def decrypt(hex_string) 
    out_chunks = []
    i = 0
    in_chunk_size = @size * 2
    out_chunk_size = (@size - 1) * 2
    while i < hex_string.length
      in_chunk = hex_string[i, in_chunk_size]
      if @chunk_cache.include? in_chunk
        out_chunk = @chunk_cache[in_chunk]
      else
        out_chunk = raw_crypt(BigNum.from_hex(in_chunk)).to_hex
        
        # This indicates a decryption error. However, we'll truncate the
        # result, so the visualization can work.
        if out_chunk.length > out_chunk_size
          out_chunk = out_chunk[0, out_chunk_size]
        end
        @chunk_cache[in_chunk] = out_chunk
      end
      
      if out_chunk.length < out_chunk_size
        out_chunks << ('0' * (out_chunk_size - out_chunk.length))
      end
      out_chunks << out_chunk
      i += in_chunk_size
    end
    out_chunks.join
  end
end  # class RsaKey


# Processes an image encrypted with an RSA key.
class EncryptedImage < Object
  attr_accessor :key, :encrypted_rows, :rows, :columns
  
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
  
  # Appends a row of encrypted pixel data to the image.
  def add_row(encrypted_row_data)
    @encrypted_rows << encrypted_row_data
  end
  
  # Decrypts the encrypted image.
  def decrypt_image
    return if @rows != nil
    @rows = []
    @encrypted_rows.each do |encrypted_row|
      row = @key.decrypt encrypted_row
      row_size = @columns && (@columns * 6) 
      row = row[0, row_size]
      @rows << row
    end
  end
  
  # Returns a list of strings representing the image data.
  def to_line_list
    decrypt_image
    @rows
  end
  
  # Writes a textual description of the image data to an io. 
  #
  # Args:
  #   io:: An io object that receives the image data
  def to_io(io) 
    to_line_list.each do |line|
      io.write "#{line}\n"
    end
  end
  
  # A dict that obeys the JSON format, representing the image.
  def as_json
    decrypt_image
    jso = {}
    jso['image'] = [ :rows => @rows.length, :cols => (@rows[0].length / 6), 
        :data => @rows ]
    jso['encrypted'] = [ :rows => @rows.length, 
        :cols => (@encrypted_rows[0].length / 6), :data => @encrypted_rows ]
  end
  
  # Reads an encrypted image description from an io.
  #
  # Args:
  #   io:: an io object supplying the input 
  # Returns a new RsaImageDecrypter instance.
  def self.from_io(io) 
    image = EncryptedImage.new
    while command = io.gets.split
      case command[0]
        when 'key'
          image.set_key command[1], command[2]
        when 'sx'
          image.columns = command[1].to_i
        when 'row'
          image.add_row command[1]
        when 'end'
          break
      end
    end
    image
  end
end  # class EncryptedImage


# Command-line controller.
if __FILE__ == $0
  image = EncryptedImage.from_io STDIN
  
  if ENV['TRACE'] == 'jsonp'
    STDOUT.write 'onJsonp('
    json.dump image.as_json, STDOUT
    STDOUT.write ');\n'
  else
    image.to_io STDOUT
  end
end