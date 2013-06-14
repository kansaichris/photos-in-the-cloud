require 'net/http'

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
        sha1_hash      = Digest::SHA1.hexdigest @file_contents

        # Amazon S3-related variables
        @bucket_name   = bucket_name
        @file_path     = path + "/" + sha1_hash[0..1] + "/" + sha1_hash[2..-1]
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

    # Open a file & determine its MIME type by reading its magic header
    def get_type filename
        # I'm currently checking for the following two magic headers:
        # FF D8 FF E0 xx xx 4A 46 49 46 00 - JPEG/JFIF graphics file
        # FF D8 FF E1 xx xx 45 78 69 66 00 - Digital camera JPG using EXIF
        # For more information, see
        # http://www.garykessler.net/library/file_sigs.html
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
        # Selected elements from the Amazon S3 request to sign
        #
        # For more information, see
        # http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
        string  = "PUT\n"
        string << "#{@md5_hash}\n"
        string << "#{@file_type}\n"
        string << "#{@date}\n"
        # string << amz_headers
        string << "/#{@bucket_name}/#{@file_path}"
    end
end
