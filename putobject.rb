require_relative 's3file'
require 'net/http'

class PUTObject
    def initialize(file, bucket_name, region, path, date, id, key)
        # File and date
        @file          = file
        sha1_hash      = @file.sha1_hash
        @date          = date

        # Amazon S3 setup
        @bucket_name   = bucket_name
        @file_path     = path + "/" + sha1_hash[0..1] + "/" + sha1_hash[2..-1]
        @host_name     = "#{@bucket_name}.#{region}.amazonaws.com"

        init_headers_with_key id, key
    end

    def init_headers_with_key id, key
        @headers = Hash.new
        @headers['Content-MD5']    = @file.md5_hash
        @headers['Content-Type']   = @file.mime_type
        @headers['Content-Length'] = @file.size.to_s
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


        http.send_request('PUT', "/" + @file_path, @file.content, @headers)
    end

    def string_to_sign
        # Selected elements from the Amazon S3 request to sign
        #
        # For more information, see
        # http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
        string  = "PUT\n"
        string << "#{@file.md5_hash}\n"
        string << "#{@file.mime_type}\n"
        string << "#{@date}\n"
        # string << amz_headers
        string << "/#{@bucket_name}/#{@file_path}"
    end
end
