#!/usr/bin/env rvm 1.9.3 do ruby

# Upload a file to Amazon S3 using its SHA-1 hash as its filename

require_relative 'options'
require_relative 'image'
require_relative 'utility'
require_relative 'worker'

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

# Set up a job queue
job_queue = Queue.new

# Configure Amazon Web Services
AWS.config(config)

# Get an instance of the S3 interface using the default configuration
s3 = AWS::S3.new

# Get a reference to the specified bucket
bucket = s3.buckets[opts[:bucket]]

# Create a queue for the threads to use to communicate upload progress
byte_queue = Queue.new

# Upload a single file #########################################################
if opts[:file]
    puts "Files to upload: 1"
    puts "   1: #{opts[:file]}"
    image = Image.new(opts[:file])
    # Set the counter for the number of files to upload
    count = 1
    # Set the counter for the number of bytes to upload
    bytes = image.size

    # Create a new thread to upload the specified file
    # NOTE: This isn't really necessary, but it will probably make further
    #       refactoring easier because threads are used to recursively upload
    #       files in a directory.
    job_queue << Proc.new do
        # NOTE: upload_to sends data incrementally and yields the number of
        #       bytes uploaded each time. Those bytes are pushed onto the
        #       queue for the progress bar to use later
        image.upload_to(bucket) { |bytes| byte_queue << bytes }
    end
end

# Upload all of the files in a directory #######################################
if opts[:dir]
    # Recursively find all of the image files in the specified directory
    image_glob = File.join(File.expand_path(opts[:dir]), "**", "*.{jpg,JPG}")
    images = Dir[image_glob].map { |filename| Image.new(filename) }
    # Print the number of files to upload
    puts "#{images.size} image files found"
    # Set the counter for the number of files to upload (incremented below)
    count = 1
    # Set the counter for the number of bytes to upload (incremented below)
    bytes = 0
    # Set the (printf) format to use when printing the filenames below
    upload_format = "%4d: %-50s (%d bytes)\n"
    uploaded_format = "%4d: %-50s (already uploaded)\n"

    images.each do |image|
        if image.exists_in?(bucket)
            printf(uploaded_format, count, truncate(File.basename(image.path), 50))
            count += 1
            next
        end

        # Print the name and number of each file that will be uploaded
        printf(upload_format, count, truncate(File.basename(image.path), 50), image.size)
        # Increment the counter for the number of files
        count += 1
        # Add the file size to the total number of bytes to upload
        bytes += image.size
        # Create a new thread to upload the file
        job_queue << Proc.new do
            # NOTE: upload_to sends data incrementally and yields the number of
            #       bytes uploaded each time. Those bytes are pushed onto the
            #       queue for the progress bar to use later
            image.upload_to(bucket) { |bytes| byte_queue << bytes }
        end
    end
end

# Create a new progress bar
bar = ProgressBar.create(:starting_at => 0,
                         :total => bytes,
                         :format => "%a |%w>%i| (%c of %C bytes sent)")

# Create a new thread to update the progress bar until all of the files (bytes)
# have been uploaded
progress_thread = Thread.new do
     until bar.finished?
         bar.progress += byte_queue.pop
     end
end

# Spin up five workers
workers = []
(1..5).each do
    workers << Worker.new(job_queue)
end

# Shut down each of the workers once the job queue is empty
sleep 0.1 until job_queue.empty?
workers.each { |worker| worker.shut_down }

progress_thread.join
