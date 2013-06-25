class S3Bucket
    def initialize(name, region="s3")
        @name = name
        @region = region
    end

    def host
        "#{@name}.#{@region}.amazonaws.com"
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

        # Send the request #####################################################
        send_request('PUT', file_path, aws_key, headers, file.content)
    end

    def send_request(verb, path, aws_key, headers, data = nil)
        # Make sure that the HTTP verb is uppercase
        verb.upcase!

        # Build a string to sign for Amazon's authentication header ############
        #
        # For more information, see
        # http://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
        #
        string_to_sign  = "#{verb}\n"
        string_to_sign << headers['Content-MD5'] unless headers['Content-MD5'].nil?
        string_to_sign << "\n"
        string_to_sign << headers['Content-Type'] unless headers['Content-Type'].nil?
        string_to_sign << "\n"
        string_to_sign << headers['Date'] unless headers['Date'].nil?
        string_to_sign << "\n"
        # NOTE: Add AMZ headers, if any, here
        # string_to_sign << amz_headers
        string_to_sign << "/#{name}/#{path}"

        # Calculate the authentication header ##################################
        headers['Authorization'] = auth_header(aws_key, string_to_sign)

        puts "DEBUG: Printing HTTP headers in the PUT OBJECT request:"
        puts "-------------------------------------------------------"
        headers.each do |key,value|
            puts "#{key} = #{value}"
        end
        puts "-------------------------------------------------------"

        uri = URI.parse("http://#{host}/")
        http = Net::HTTP.new(uri.host, uri.port)
        # NOTE: I may want to use the following options at some point...
        # http.use_ssl = true
        # http.verify_mode = ?
        # TIP: Try uncommenting the following line to debug issues!
        # http.set_debug_output($stdout)

        # TODO: Check to see if the file already exists. If it does,
        #       don't bother to upload this one because it has the same
        #       SHA-1 hash and thus the same content.

        http.send_request(verb, "/" + path, data, headers)
    end

    # Calculate the authentication header for an Amazon Web Services request
    def auth_header(aws_key, string_to_sign)
        signature = hmac_signature(aws_key.secret, string_to_sign)
        header = "AWS #{aws_key.id}:#{signature}"
    end

    # Calculate the Base64-encoded SHA-1 HMAC signature of a key and string
    def hmac_signature(key, string_to_sign)
        digest = OpenSSL::HMAC.digest('sha1', key, string_to_sign)
        signature = Base64.encode64(digest)
    end

    attr_reader :name, :region
end
