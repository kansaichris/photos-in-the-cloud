#!/usr/bin/env ruby

require 'trollop'

require 'RMagick'
include Magick

################################################################################
# COMMAND-LINE OPTIONS
################################################################################

def process_options
    parser = Trollop::Parser.new do
        version "Amazon S3 Photo Management Tools 0.5.0 (c) 2013 Christopher Frederick"

        banner <<-EOS
This program makes thumbnails.

Usage:
    make_thumbnail.rb [options]

Options:
        EOS

        opt :file, "Original photo",
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

file_path = opts[:file]
extension = File.extname(file_path)
base_name = File.basename(file_path, extension)

thumbnail_sizes = [
  [100, 100],
  [150, 150],
  [400, 300],
  [600, 450],
  [800, 600],
  [1024, 768],
  [1280, 960],
  [1600, 1200]
]

Dir.mkdir("thumbnails") unless Dir.exists?("thumbnails")

image = Image.read(file_path).first

thumbnail_sizes.each do |width, height|
  thumbnail = image.change_geometry("#{width}x#{height}") do |cols, rows, img|
    img.resize(cols, rows)
  end
  # thumbnail = image.resize_to_fill(width, height)
  thumbnail.write("thumbnails/#{base_name}-#{thumbnail.columns}x#{thumbnail.rows}#{extension}")

  thumbnail.destroy!
end

image.destroy!
