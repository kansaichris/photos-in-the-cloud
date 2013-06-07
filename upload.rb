#!/usr/bin/env rvm 1.9.3 do ruby

# Upload a file to Amazon S3 using its SHA-1 hash as its filename

require 'base64'
require 'cgi'
require 'openssl'
require 'digest/sha1'

require 'trollop'

# Selected elements from the Amazon S3 request to sign
#
# For more information, see
# http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html

# TODO: Calculate the MD5 hash for the file

###############################################################################
# Step 1: Parse command-line options
###############################################################################

# Get command-line options as a hash object with Trollop
# opts[:file] holds the specified file,
# opts[:bucket] holds the specified bucket, etc.
opts = Trollop::options do
    version "S3 Photo Manager 0.0.1 (c) 2013 Christopher Frederick"
    opt :file, "File to upload", :type => :string
    opt :bucket, "Amazon S3 bucket", :type => :string
    opt :path, "Photo path (filename prefix) in the specified bucket", :type => :string
    opt :aws_key_id, "Access key ID for Amazon Web Services", :type => :string
    opt :aws_secret_key, "Secret access key for Amazon Web Services", :type => :string
end

# --file must be specified
Trollop::die :file, "must be specified" unless opts[:file]

# --file must indicate a valid file
Trollop::die :file, "must be a valid file" unless File.exists?(opts[:file])

# --bucket must be specified
Trollop::die :bucket, "must be specified" unless opts[:bucket]

# --path must be specified
Trollop::die :path, "must be specified" unless opts[:path]

# --aws-key-id must be specified
Trollop::die :aws_key_id, "must be specified" unless opts[:aws_key_id]

# --aws-secret-key must be specified
Trollop::die :aws_secret_key, "must be specified" unless opts[:aws_secret_key]

# DEBUG: Print the opts hash
p opts

###############################################################################
# Step 2: Examine the file to upload
###############################################################################

# Open the file & determine its MIME type by reading its magic header
# For more information, see
# http://www.garykessler.net/library/file_sigs.html
filename = opts[:file]
file = File.open(filename, "rb")

# I'm currently checking for the following two magic headers:
# FF D8 FF E0 xx xx 4A 46 49 46 00 - JPEG/JFIF graphics file
# FF D8 FF E1 xx xx 45 78 69 66 00 - Digital camera JPG using EXIF
file_type = ''
jpg_regexp = Regexp.new("\xff\xd8\xff(\xe0|\xe1).{2}JFIF".force_encoding("binary"))
case IO.read(filename, 10)
when /^#{jpg_regexp}/
    file_type = 'image/jpeg'
end

# Abort if the file doesn't have one of the magic headers listed above
# TODO: Add more file types as necessary
if file_type.empty?
    puts "#{filename} does not appear to be a supported file type"
    puts "This script currently only supports JPEG files"
    abort
end

###############################################################################
# Step 3: Get the current time
###############################################################################

# %a - Abbreviated weekday name ("Sun")
# %d - Day of the month, zero-padded (01..31)
# %b - Abbreviated month name ("Jan")
# %Y - Year with century (can be negative, 4 digits at least)
# %H - Hour of the day, 24-hour clock, zero-padded (00..23)
# %M - Minute of the hour (00..59)
# %S - Second of the minute (00..60)
# %z - Time zone as hour and minute offset from UTC (e.g. +0900)
# Example: Sun, 01 Jan 2001 00:00:00 +0900
time_string = Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")

# Calculate the file's SHA-1 hash
file_size = file.size
file_contents = file.read
sha1_hash = Digest::SHA1.hexdigest "blob #{file_size}\0#{file_contents}"

# Calculate the file's MD5 hash
md5_hash = Digest::MD5.base64digest file_contents

###############################################################################
# Step 4: Set the string to sign with your AWS secret access key
###############################################################################

bucket_name = opts[:bucket]
folder_name = opts[:path]
  file_name = sha1_hash
string_to_sign = "PUT
#{md5_hash}
#{file_type}
#{time_string}
/#{bucket_name}/#{folder_name}/#{file_name}"

# DEBUG: Print the string to sign
puts "DEBUG: The string to sign is:\n\n"
puts "-------------------------------\n#{string_to_sign}\n-------------------------------\n\n"

# Get the AWS secret access key
secret_access_key = opts[:aws_secret_key]

# Calculate a Base64-encoded SHA-1 HMAC signature from
# string_to_sign and secret_access_key

hmac_digest = OpenSSL::HMAC.digest('sha1', secret_access_key, string_to_sign)
hmac_signature = Base64.encode64(hmac_digest)

# DEBUG: Print the HMAC signature
puts "DEBUG: The HMAC signature is #{hmac_signature}\n"

# Close the file
file.close
