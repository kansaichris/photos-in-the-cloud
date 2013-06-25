#!/usr/bin/env rvm 1.9.3 do ruby

# Upload a file to Amazon S3 using its SHA-1 hash as its filename

require_relative 'utility'
require_relative 'options'
require_relative 'putobject'

require 'digest/sha1'
require 'nokogiri'

###############################################################################
# MAIN
###############################################################################

opts = process_options

file = S3File.new(opts[:file], "r")

=begin
puts "DEBUG: Details on #{file.path}"
puts "------------------------------"
puts "MIME type: #{file.mime_type}"
puts "MD5 hash: #{file.md5_hash}"
puts "SHA-1 hash: #{file.sha1_hash}"
puts "------------------------------"
=end

put_request = PUTObject.new(file, opts[:bucket], opts[:region], opts[:path], current_time, opts[:aws_key_id], opts[:aws_secret_key])

put_request.print_headers

response = put_request.get_response

puts "Response code: #{response.code}"
puts "Response message: #{response.message}"
puts "Response class: #{response.class.name}"

puts
puts "DEBUG: HTTP headers in the response:"
puts "------------------------------------"
response.each do |key,value|
    puts "#{key} = #{value}"
end
puts "------------------------------------"
puts
puts response.body

=begin
puts "DEBUG: Keys in the response:"
puts "----------------------------"
xml_reader = Nokogiri::XML::Reader(response.body)
xml_reader.each do |node|
    #if node.name == "Key"
        puts node.inner_xml
    #end
end
puts "----------------------------"
puts
=end

=begin
# Calculate the file's SHA-1 hash ##############################################
file_size = file.size
file_contents = file.read
sha1_hash = Digest::SHA1.hexdigest "blob #{file_size}\0#{file_contents}"
=end

=begin
string2 = "GET


Tue, 27 Mar 2007 19:36:42 +0000
/johnsmith/photos/puppy.jpg".force_encoding("UTF-8")

puts "DEBUG: Sample string to sign is:\n\n"
puts "-------------------------------\n#{string2}\n-------------------------------\n\n"

key2 = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
digest2 = OpenSSL::HMAC.digest( 'sha1', key2, string2)
digest3 = OpenSSL::HMAC.digest( 'sha1', string2, key2)
signature2 = Base64.encode64(digest2)
signature3 = Base64.encode64(digest3)

puts "DEBUG: The calculated signature is #{signature2}\n"
puts "DEBUG: The calculated signature is #{signature3}\n"
=end
