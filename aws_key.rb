class AWSKey
    def initialize(id, secret)
        @id = id
        @secret = secret
    end

    attr_reader :id, :secret
end
