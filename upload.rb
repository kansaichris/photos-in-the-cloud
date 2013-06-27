#!/usr/bin/env rvm 1.9.3 do ruby

# Upload a file to Amazon S3 using its SHA-1 hash as its filename

require_relative 'options'
require_relative 's3bucket'

require 'digest/sha1'

###############################################################################
# MAIN
###############################################################################

opts = process_options

file    = S3File.new(opts[:file], "r")
bucket  = S3Bucket.new(opts[:bucket], opts[:region])
aws_key = AWSKey.new(opts[:aws_key_id], opts[:aws_secret_key])

=begin
puts "DEBUG: Details on #{file.path}"
puts "------------------------------"
puts "MIME type: #{file.mime_type}"
puts "MD5 hash: #{file.md5_hash}"
puts "SHA-1 hash: #{file.sha1_hash}"
puts "------------------------------"
=end




response = bucket.put_file(file, aws_key, opts[:path])

puts "RESPONSE:"
puts "---------"
puts "Body: #{response.body}"
puts "Code: #{response.code}"
puts "Message: #{response.message}"
puts "Headers: #{response.headers.inspect}"
puts "---------"
