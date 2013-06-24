require_relative 's3file'
require 'net/http'

class PUTObject
    def initialize(file, bucket_name, region, path, date, id, key)

        # Get the file's SHA-1 hash
        sha1_hash = file.sha1_hash
        file_path = path + "/" + sha1_hash[0..1] + "/" + sha1_hash[2..-1]

        # Init headers
        @headers = Hash.new
        @headers['Content-MD5']    = file.md5_hash
        @headers['Content-Type']   = file.mime_type
        @headers['Content-Length'] = file.size.to_s
        @headers['Date']           = date

        # Selected elements from the Amazon S3 request to sign
        #
        # For more information, see
        # http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
        string_to_sign  = "PUT\n"
        string_to_sign << @headers['Content-MD5'] unless @headers['Content-MD5'].nil?
        string_to_sign << "\n"
        string_to_sign << @headers['Content-Type'] unless @headers['Content-Type'].nil?
        string_to_sign << "\n"
        string_to_sign << @headers['Date'] unless @headers['Date'].nil?
        string_to_sign << "\n"
        # NOTE: Add AMZ headers, if any, here
        # See instructions on how to canonicalize these headers at
        # http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
        # string_to_sign << amz_headers
        string_to_sign << "/#{bucket_name}/#{file_path}"

        @headers['Authorization']  = auth_header(id, key, string_to_sign)

        # Amazon S3 setup
        @host_name = "#{bucket_name}.#{region}.amazonaws.com"

        @file = file
        @file_path = file_path
    end

    # Calculate the Base64-encoded SHA-1 HMAC signature of a key and string
    def hmac_signature(key, string_to_sign)
        digest = OpenSSL::HMAC.digest('sha1', key, string_to_sign)
        signature = Base64.encode64(digest)
    end

    # Calculate the authentication header for an Amazon Web Services request
    def auth_header(access_key_id, secret_access_key, string_to_sign)
        signature = hmac_signature(secret_access_key, string_to_sign)
        header = "AWS #{access_key_id}:#{signature}"
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

        # TODO: Check to see if the file already exists. If it does,
        #       don't bother to upload this one because it has the same
        #       SHA-1 hash and thus the same content.

        http.send_request('PUT', "/" + @file_path, @file.content, @headers)
    end
end
