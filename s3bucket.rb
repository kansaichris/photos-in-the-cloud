require_relative 's3file'
require_relative 'aws_key'
require_relative 'utility'

require 'httparty'

class S3Bucket

    include HTTParty

    def initialize(name, region="s3")
        @name = name
        @region = region
    end

    def hostname
        "#{@name}.#{@region}.amazonaws.com"
    end

    def contains?(file_path, aws_key)
        # Initialize the HEAD request's HTTP headers
        headers = Hash.new
        headers['Date']           = current_time

        # Send the request
        response = send_request('HEAD', file_path, aws_key, headers)

        # Check the return code
        response.code == 200
    end

    def put_file(file, aws_key, path="")
        # Initialize the PUT request's HTTP headers ############################
        headers = Hash.new
        headers['Content-MD5']    = file.md5_hash
        headers['Content-Type']   = file.mime_type
        headers['Content-Length'] = file.size.to_s
        headers['Date']           = current_time

        # Calculate the file's SHA-1 hash to use as its path ###################
        sha1_hash = file.sha1_hash
        file_path = path + "/" + sha1_hash[0..1] + "/" + sha1_hash[2..-1]

        # Send the request, but only if the file doesn't already exist #########
        send_request('PUT', file_path, aws_key, headers, file.content) unless contains?(file_path, aws_key)
    end

    def send_request(verb, path, aws_key, headers, data = nil)
        # Build a string to sign for Amazon's authentication header ############
        #
        # For more information, see
        # http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
        #
        string_to_sign = <<-STRING
#{verb.upcase}
#{headers['Content-MD5']}
#{headers['Content-Type']}
#{headers['Date']}
        STRING
        # NOTE: Add AMZ headers, if any, here
        # string_to_sign << amz_headers
        string_to_sign << "/#{name}/#{path}"

        # Calculate the authentication header ##################################
        headers['Authorization'] = aws_key.auth_header(string_to_sign)

=begin
        puts "DEBUG: Printing HTTP headers in the request:"
        puts "--------------------------------------------"
        headers.each do |key,value|
            puts "#{key} = #{value}"
        end
        puts "--------------------------------------------"
=end

        self.class.base_uri "http://#{hostname}/"
        self.class.send(verb.downcase, "/" + path, :headers => headers, :body => data)
    end

    attr_reader :name, :region
end
