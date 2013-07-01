require 'trollop'

# Get command-line options as a hash object with Trollop #######################
# opts[:file] holds the specified file,
# opts[:bucket] holds the specified bucket, etc.
def process_options
    parser = Trollop::Parser.new do
        version "Amazon S3 Photo Uploader 0.1.0 (c) 2013 Christopher Frederick"

        banner <<-EOS
This program uploads a file to an Amazon S3 bucket.

Usage:
    upload.rb [options]

Options:
        EOS

        opt :file, "File to upload",
            :type => :string, :required => true

        opt :bucket, "Amazon S3 bucket",
            :type => :string, :required => true

        # For more information on Amazon S3 regions, see
        # http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
        opt :region, "Region where the bucket is located. By default, this is 's3' for US Standard. Use 's3-us-west-2' for US West (Oregon), 's3-us-west-1' for US West (Northern California), 's3-eu-west-1' for EU (Ireland), 's3-ap-southeast-1' for Asia Pacific (Singapore), 's3-ap-southeast-2' for Asia Pacific (Sydney), 's3-ap-northeast-1' for Asia Pacific (Tokyo), and 's3-sa-east-1' for South America (Sao Paulo)",
            :type => :string, :default => 's3'

        opt :aws_key_id, "Access key ID for Amazon Web Services",
            :type => :string

        opt :aws_secret_key, "Secret access key for Amazon Web Services",
            :type => :string
    end

    Trollop::with_standard_exception_handling parser do
        raise Trollop::HelpNeeded if ARGV.empty? # show help
        parser.parse ARGV
    end
end
