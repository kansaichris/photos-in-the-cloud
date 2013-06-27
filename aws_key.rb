class AWSKey
    def initialize(id, secret)
        @id = id
        @secret = secret
    end

    # Calculate the authentication header for an Amazon Web Services request
    def auth_header(string_to_sign)
        # Calculate the Base64-encoded SHA-1 HMAC signature
        digest = OpenSSL::HMAC.digest('sha1', @secret, string_to_sign)
        signature = Base64.encode64(digest)

        # Construct the authentication header
        header = "AWS #{@id}:#{signature}"
    end

    attr_reader :id, :secret
end
