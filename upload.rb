#!/usr/bin/env rvm 1.9.3 do ruby

# Upload a file to Amazon S3 using its SHA-1 hash as its filename

require_relative 'options'
require_relative 's3bucket'

################################################################################
# MAIN
################################################################################

opts = process_options

file    = S3File.new(opts[:file], "r")
bucket  = S3Bucket.new(opts[:bucket], opts[:region])
aws_key = AWSKey.new(opts[:aws_key_id], opts[:aws_secret_key])

puts
puts "Uploading #{file.path} to #{bucket.hostname}..."
puts <<FILE_INFO
--------------------------------------------------------------------------------
DEBUG: The file's MIME type is #{file.mime_type}
DEBUG: The file's MD5 hash is #{file.md5_hash}
DEBUG: The file's SHA-1 hash is #{file.sha1_hash}
--------------------------------------------------------------------------------
FILE_INFO

response = bucket.put_file(file, aws_key)

unless response.nil?
    headers  = response.headers.map { |key, value| "DEBUG: #{key} = #{value.join(', ')}" }

    puts
    puts "Printing response..."
    puts <<-RESPONSE
--------------------------------------------------------------------------------
DEBUG: The HTTP status code is #{response.code} #{response.message}
DEBUG: The response headers are
#{ headers.join("\n") }
--------------------------------------------------------------------------------
    RESPONSE
end
