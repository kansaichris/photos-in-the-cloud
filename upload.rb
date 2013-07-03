#!/usr/bin/env rvm 1.9.3 do ruby

# Upload a file to Amazon S3 using its SHA-1 hash as its filename

require_relative 'options'
require_relative 'image'

require 'rubygems'
require 'yaml'
require 'aws-sdk'
require 'ruby-progressbar'
require 'thread'


################################################################################
# Process YAML and command-line options
################################################################################

# Read the YAML config file if it exists
config_file = File.join(File.dirname(__FILE__), "config.yml")
config = File.exist?(config_file) ? YAML.load(File.read(config_file)) : Hash.new

# If the YAML config file wasn't formatted correctly, quit with an error message
unless config.kind_of?(Hash)
  puts <<END
config.yml is formatted incorrectly.  Please use the following format:

access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY

END
  exit 1
end

# Process command-line options
opts = process_options

# Command-line options take priority over YAML configuration
config['access_key_id'] = opts[:aws_key_id] unless opts[:aws_key_id].nil?
config['secret_access_key'] = opts[:aws_secret_key] unless opts[:aws_secret_key].nil?

# If no AWS access keys have been specified, quit with an error message
if config['access_key_id'].nil? || config['secret_access_key'].nil?
    puts <<END
Specify your AWS credentials on the command-line or in config.yml as follows:

access_key_id: YOUR_ACCESS_KEY_ID
secret_access_key: YOUR_SECRET_ACCESS_KEY

END
    exit 1
end

################################################################################
# MAIN
################################################################################

# Configure Amazon Web Services
AWS.config(config)

# Get an instance of the S3 interface using the default configuration
s3 = AWS::S3.new

# Get a reference to the specified bucket
bucket = s3.buckets[opts[:bucket]]

threads = []
queue = Queue.new

if opts[:file]
    puts "Files to upload: 1"
    puts "   1: #{opts[:file]}"
    image = Image.new(opts[:file])
    count = 1
    bytes = image.size

    # Upload the specified file
    threads << Thread.new do
        image.upload_to(bucket) { |bytes| queue << bytes }
    end
end

if opts[:dir]
    # Print all image files in the directory to upload
    image_glob = File.join(opts[:dir], "**", "*.jpg")
    images = Dir[image_glob]
    puts "Files to upload: #{images.size}"
    count = 1
    bytes = 0
    format = "%4d: %s\n"
    # Upload each file
    images.each do |filename|
        printf(format, count, filename)
        count += 1
        bytes += File.size(filename)
        threads << Thread.new do
            image = Image.new(filename)
            image.upload_to(bucket) { |bytes| queue << bytes }
        end
    end
end

# Progress bar #################################################################
bar = ProgressBar.create(:starting_at => 0,
                         :total => bytes,
                         :format => "%a |%w>%i| (%c of %C bytes sent)")

progress_thread = Thread.new { bar.progress += queue.pop until bar.finished? }
progress_thread.join
################################################################################
