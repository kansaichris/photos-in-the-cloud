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

        opt :region, "Region where the bucket is located. By default, this is US Standard. Use 'us-west-2' for US West (Oregon), 'us-west-1' for US West (Northern California), 'eu' for EU (Ireland), 'ap-southeast-1' for Asia Pacific (Singapore), 'ap-southeast-2' for Asia Pacific (Sydney), 'ap-northeast-1' for Asia Pacific (Tokyo), and 'sa-east-1' for South America (Sao Paulo)",
            :type => :string

        opt :path, "Photo path (filename prefix) in the specified bucket",
            :type => :string, :required => true

        opt :aws_key_id, "Access key ID for Amazon Web Services",
            :type => :string, :required => true

        opt :aws_secret_key, "Secret access key for Amazon Web Services",
            :type => :string, :required => true
    end

    Trollop::with_standard_exception_handling parser do
        raise Trollop::HelpNeeded if ARGV.empty? # show help
        parser.parse ARGV
    end
end
