#!/usr/bin/env rvm 1.9.3 do ruby

require_relative 'image'

require 'trollop'

################################################################################
# COMMAND-LINE OPTIONS
################################################################################

def process_options
    parser = Trollop::Parser.new do
        version "Amazon S3 Photo Management Tools 0.5.0 (c) 2013 Christopher Frederick"

        banner <<-EOS
This program shows a photo's Exif data.

Usage:
    view_exif_data.rb [options]

Options:
        EOS

        opt :file, "Photo with Exif data to view",
            :type => :string, :required => true

    end

    Trollop::with_standard_exception_handling parser do
        raise Trollop::HelpNeeded if ARGV.empty? # show help
        parser.parse ARGV
    end
end

opts = process_options

################################################################################
# MAIN
################################################################################

exit 1 unless opts[:file]

image = Image.new(opts[:file])

image.tags.each do |key,value|
    puts "#{key} = #{value}"
end
