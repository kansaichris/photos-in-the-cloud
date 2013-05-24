#!/usr/bin/ruby

# Upload a file to Amazon S3 using its SHA-1 hash as its filename

require 'base64'
require 'cgi'
require 'openssl'

# Selected elements from the Amazon S3 request to sign
#
# For more information, see
# http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html

# TODO: Accept a filename from the command line
# TODO: Calculate the MD5 hash for the file
# TODO: Get the file's type

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

string_to_sign = "PUT

image/jpeg
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
