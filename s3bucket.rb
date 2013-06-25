class S3Bucket
    def initialize(name, region="s3")
        @name = name
        @region = region
    end

    def host
        "#{@name}.#{@region}.amazonaws.com"
    end

    attr_reader :name, :region
end
