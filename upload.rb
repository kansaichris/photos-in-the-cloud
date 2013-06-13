#!/usr/bin/env rvm 1.9.3 do ruby

# Upload a file to Amazon S3 using its SHA-1 hash as its filename

require_relative 'utility'

require 'cgi'
require 'digest/sha1'
require 'net/http'

require 'trollop'
require 'nokogiri'

###############################################################################
# Classes
###############################################################################

class PUTObject
    def initialize(filename, bucket_name, region, path, date, id, key)
        # These variables are used to calculate the authentication header:
        # - @md5_hash
        # - @file_type
        # - @date
        # - @bucket_name
        # - @file_path

        # These variables are used in the other request headers:
        # - @md5_hash  ('Content-MD5')
        # - @file_type ('Content-Type')
        # - @file_size ('Content-Length')
        # - @date      ('Date')

        # File-related variables
        @file_contents = File.read(filename, @file_size)
        @file_size     = File.size(filename)
        @file_type     = get_type filename
        @md5_hash      = Digest::MD5.base64digest @file_contents

        # Amazon S3-related variables
        @bucket_name   = bucket_name
        @file_path     = path + "/" + filename
        @host_name     = "#{@bucket_name}.#{region}.amazonaws.com"

        # Time-related variables
        @date          = date

        init_headers_with_key id, key
    end

    def init_headers_with_key id, key
        @headers = Hash.new
        @headers['Content-MD5']    = @md5_hash
        @headers['Content-Type']   = @file_type
        @headers['Content-Length'] = @file_size.to_s
        @headers['Date']           = @date
        @headers['Authorization']  = auth_header(id, key, string_to_sign)
    end

    def print_headers
        puts "DEBUG: Printing HTTP headers in the PUT OBJECT request:"
        puts "-------------------------------------------------------"
        @headers.each do |key,value|
            puts "#{key} = #{value}"
        end
        puts "-------------------------------------------------------"
    end

    def get_response
        uri = URI.parse("http://#{@host_name}/")
        http = Net::HTTP.new(uri.host, uri.port)
        # NOTE: I may want to use the following options at some point...
        # http.use_ssl = true
        # http.verify_mode = ?
        # TIP: Try uncommenting the following line to debug issues!
        # http.set_debug_output($stdout)

        http.send_request('PUT', "/" + @file_path, @file_contents, @headers)
    end

    def get_type filename
        # I'm currently checking for the following two magic headers:
        # FF D8 FF E0 xx xx 4A 46 49 46 00 - JPEG/JFIF graphics file
        # FF D8 FF E1 xx xx 45 78 69 66 00 - Digital camera JPG using EXIF
        type = ''
        jpg_regexp = Regexp.new("\xff\xd8\xff(\xe0|\xe1).{2}JFIF".force_encoding("binary"))
        case IO.read(filename, 10)
        when /^#{jpg_regexp}/
            type = 'image/jpeg'
        else
            type = 'binary/octet-stream'
        end
        type
    end

    def string_to_sign
        string  = "PUT\n"
        string << "#{@md5_hash}\n"
        string << "#{@file_type}\n"
        string << "#{@date}\n"
        # string << amz_headers
        string << "/#{@bucket_name}/#{@file_path}"
    end
end

class Bucket

    def initialize(name, region="s3")
        @name = name
        @region = region
    end

    def get_files_for_key(id, key)
        time = current_time()
        string_to_sign = <<-EOL
GET


#{time}
/#{@name}/
        EOL
        # Remove trailing whitespace
        string_to_sign.rstrip!
        host_name = "#{@name}.#{@region}.amazonaws.com"
        uri = URI.parse("http://#{host_name}/")
        http = Net::HTTP.new(uri.host, uri.port)
        # NOTE: I don't think that the following are necessary at this time
        # http.use_ssl = true
        # http.verify_mode = ?
        # TIP: Try uncommenting the following line to debug issues!
        # http.set_debug_output($stdout)
        request_files = Net::HTTP::Get.new(uri.request_uri)
        request_files.delete 'Accept'
        request_files.delete 'User-Agent'
        request_files.add_field 'Host', host_name
        request_files.add_field 'Date', time
        request_files.add_field 'Authorization', auth_header(id, key, string_to_sign)
        # NOTE: The following may be cleaner syntax...
        # request['Authorization'] = auth_header(id, key, string_to_sign)
        response = http.request(request_files)

        nodes = Array.new
        xml_reader = Nokogiri::XML::Reader(response.body)
        xml_reader.each do |node|
            if node.name == "Key"
                nodes << node.inner_xml
            end
        end
        nodes
    end

    # TODO:
    # - Method to put a file
    # - Method to Zlib-compress a file

    attr_reader :name
end

###############################################################################
# MAIN
###############################################################################

# Selected elements from the Amazon S3 request to sign
#
# For more information, see
# http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html

# Get command-line options as a hash object with Trollop #######################
# opts[:file] holds the specified file,
# opts[:bucket] holds the specified bucket, etc.
opts = Trollop::options do
    version "S3 Photo Manager 0.0.1 (c) 2013 Christopher Frederick"

    opt :file, "File to upload",
        :type => :string, :required => true

    opt :bucket, "Amazon S3 bucket",
        :type => :string, :required => true

    opt :region, "Region where the bucket is located. By default, this is US Standard. Use 'us-west-2' for US West (Oregon), 'us-west-1' for US West (Northern California), 'eu' for EU (Ireland), 'ap-southeast-1' for Asia Pacific (Singapore), 'ap-southeast-2' for Asia Pacific (Sydney), 'ap-northeast-1' for Asia Pacific (Tokyo), and 'sa-east-1' for South America (Sao Paulo)",
        :type => :string

    opt :path, "Photo path (filename prefix) in the specified bucket",
        :type => :string, :required => true

    opt :aws_key_id, "Access key ID for Amazon Web Services",
        :type => :string, :required => true

    opt :aws_secret_key, "Secret access key for Amazon Web Services",
        :type => :string, :required => true
end
################################################################################

put_request = PUTObject.new(opts[:file], opts[:bucket], opts[:region], opts[:path], current_time, opts[:aws_key_id], opts[:aws_secret_key])
puts "DEBUG: String to sign:"
puts "----------------------"
puts put_request.string_to_sign
puts "----------------------"
puts
=begin
hash = Digest::MD5.base64digest put_request.body
puts "MD5 hash of request body: #{hash}"
puts "Class of request body: #{put_request.body.class.name}"
puts "Encoding of request body: #{put_request.body.encoding.name}"
puts "Number of bytes in request body: #{put_request.body.bytesize}"
puts "First character in request body: #{put_request.body.getbyte(4)}"
# IO.write("image.jpg", put_request.body.force_encoding("UTF-8"))
=end

response = put_request.get_response
# response = http.request(put_request)

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
# Get a list of the files in the specified bucket
my_bucket = Bucket.new(opts[:bucket], opts[:region])
files = my_bucket.get_files_for_key(opts[:aws_key_id], opts[:aws_secret_key])

# Print all of the filenames
unless files.empty?
    puts "Received the following filenames:"
    count = 0
    files.each do |filename|
        count = count + 1
        puts "#{count}: #{filename}"
    end
end

# Open the file & determine its MIME type by reading its magic header ##########
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

# Calculate the file's SHA-1 hash ##############################################
file_size = file.size
file_contents = file.read
sha1_hash = Digest::SHA1.hexdigest "blob #{file_size}\0#{file_contents}"

# Calculate the file's MD5 hash ################################################
md5_hash = Digest::MD5.base64digest file_contents
=end
=begin
file_name = sha1_hash
string_to_sign = "PUT
#{md5_hash}
#{file_type}
#{time_string}
/#{bucket_name}/#{folder_name}/#{file_name}"
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

# Close the file
# file.close
