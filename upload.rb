#!/usr/bin/env rvm 1.9.3 do ruby

# Upload a file to Amazon S3 using its SHA-1 hash as its filename

require 'base64'
require 'cgi'
require 'openssl'

# Selected elements from the Amazon S3 request to sign
#
# For more information, see
# http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html

# TODO: Calculate the MD5 hash for the file

# Get a filename from the command line
filename = ARGV[0]
if filename.nil?
    puts "Please specify a file to upload\n\n"
    puts "Usage: #{$0} file"
    abort
end

# Quit if the filename does not indicate a valid file
if !File.file?(filename)
    puts "Could not open #{filename}: either it is not a regular file or it does not exist" 
    abort
end

# Open the file
file = File.open(filename, "r")

# Determine the file's MIME type by reading its magic header
# For more information, see
# http://www.garykessler.net/library/file_sigs.html
#
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

# Get the current time
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

# Set the string to sign with your AWS secret access key
string_to_sign = "PUT

#{file_type}
#{time_string}
/bucket/path/photo.jpg"

puts "DEBUG: The string to sign is:\n\n"
puts "-------------------------------\n#{string_to_sign}\n-------------------------------\n\n"

# Your AWS secret access key
# PLEASE DON'T COMMIT THIS IN YOUR REPOSITORY!

# TODO: Get the access key from the command-line or environment variable

secret_access_key = ''

# The Base64-encoded SHA-1 HMAC signature calculated from
# string_to_sign and your AWS secret access key

hmac_signature = CGI.escape( Base64.encode64( "#{OpenSSL::HMAC.digest( 'sha1', secret_access_key, string_to_sign)}\n") )

puts "DEBUG: The HMAC signature is #{hmac_signature}\n"

# Close the file
file.close
