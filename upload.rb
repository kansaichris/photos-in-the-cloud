#!/usr/bin/ruby

require 'base64'
require 'cgi'
require 'openssl'

# Selected elements from the Amazon S3 request to sign
#
# For more information, see
# http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html

string_to_sign = 'PUT\n
\n
image/jpeg\n
Wed, 22 May 2013 16:25:00 +0900\n
/bucket/path/photo.jpg'

# Your AWS secret access key
# PLEASE DON'T COMMIT THIS IN YOUR REPOSITORY!

secret_access_key = ''

# The Base64-encoded SHA-1 HMAC signature calculated from
# string_to_sign and your AWS secret access key

puts CGI.escape( Base64.encode64( "#{OpenSSL::HMAC.digest( 'sha1', secret_access_key, string_to_sign)}\n") )
