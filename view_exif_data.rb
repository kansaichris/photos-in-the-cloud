#!/usr/bin/env rvm 1.9.3 do ruby

require_relative 'options'
require_relative 'image'

################################################################################
# MAIN
################################################################################

# Process command-line options
opts = process_options

exit 1 unless opts[:file]

image = Image.new(opts[:file])

image.exif_tags.each do |key,value|
    puts "#{key} = #{value}"
end
