#!/usr/bin/env ruby
# encoding: UTF-8

require 'trollop'

require 'RMagick'
include Magick

###############################################################################
# COMMAND-LINE OPTIONS
###############################################################################

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

###############################################################################
# MAIN
###############################################################################

# Get the file path, base file name, and extension
file_path = opts[:file]
extension = File.extname(file_path)
base_name = File.basename(file_path, extension)

# Specify the thumbnail sizes to generate
thumbnail_sizes = [
  [100, 100],   # Tiny thumbnails
  [150, 150],   # Large thumbnails
  [400, 300],   # Small images
  [600, 450],   # Medium images
  [800, 600],   # Large images
  [1024, 768],  # Extra (X)-large images
  [1280, 960],  # X2-large images
  [1600, 1200]  # X3-large iages
]

# Create the 'thumbnails' directory unless it already exists
Dir.mkdir("thumbnails") unless Dir.exists?("thumbnails")

# Read the original image into memory
image = Image.read(file_path).first

# Generate a thumbnail for each of the specified dimensions
thumbnail_sizes.each do |width, height|
  # Of course, don't generate a thumbnail as large as the original image!
  next if width >= image.columns || height >= image.rows

  # Try to resize the image to the specified width and height while
  # maintaining its aspect ratio. The values passed into the block
  # through 'cols' and 'rows' may be slightly different from the
  # specified dimensions to ensure that the image maintains its
  # aspect ratio AND is no larger than the specified size.
  thumbnail = image.change_geometry("#{width}x#{height}") do |cols, rows, img|
    img.resize(cols, rows)
  end
  # thumbnail = image.resize_to_fill(width, height)
  thumbnail.write("thumbnails/#{base_name}-#{thumbnail.columns}x#{thumbnail.rows}#{extension}")

  # Force RMagick to free the thumbnail's image memory
  # For more details, see https://github.com/rmagick/rmagick/issues/12
  thumbnail.destroy!
end

# Force RMagick to free the original file's image memory
# For more details, see https://github.com/rmagick/rmagick/issues/12
image.destroy!
