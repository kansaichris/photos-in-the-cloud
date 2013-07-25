require 'exifr'

##
# An image stored in Amazon S3.
class Image

    # Initializes a new instance of the Image class
    #
    # @param path [String] the path to the image in the local filesystem
    def initialize path
        @path = path
        @size = File.size(path)

        # Get image metadata
        tag_array = EXIFR::JPEG.new(@path).to_hash.map do |key, value|
          # Replace underscores with dashes in the metadata tag name
          key = key.to_s.gsub(/_/, '-')
          # Prefix any Exif tag name with 'exif-'
          non_exif_tags = ['width', 'height', 'bits', 'comment']
          key.prepend('exif-') unless non_exif_tags.include?(key)
          # Return the tag and its value
          [key, value]
        end
        @tags = Hash[tag_array]
    end

    # Returns the path prefix used to store this file in an Amazon S3 bucket
    #
    # @return [String] the path prefix used to store this file in an Amazon S3
    #                  bucket
    def s3_prefix
        "objects"
    end

    # Returns this file's content
    def content
        @content ||= File.read(path, size)
    end

    # Opens this file and tries to determine its MIME type by reading its magic
    # header
    #
    # @return [String] this file's MIME type if it could be detected or
    #                  'binary/octet-stream' otherwise
    def mime_type
        # I'm currently checking for the following two magic headers:
        # FF D8 FF E0 xx xx 4A 46 49 46 00 - JPEG/JFIF graphics file
        # FF D8 FF E1 xx xx 45 78 69 66 00 - Digital camera JPG using EXIF
        # For more information, see
        # http://www.garykessler.net/library/file_sigs.html
        type = ''
        jpg_regexp = Regexp.new("\xff\xd8\xff(\xe0.{2}JFIF|\xe1.{2}Exif)".force_encoding("binary"))
        case IO.read(path, 10)
        when /^#{jpg_regexp}/
            type = 'image/jpeg'
        else
            type = 'binary/octet-stream'
        end
        type
    end

    # Returns this file's MD5 hash value as a Base64-encoded string
    #
    # @return [String] this file's MD5 hash value as a Base64-encoded string
    def md5_hash
        @md5_hash ||= Digest::MD5.base64digest content
    end

    # Returns this file's SHA-1 hash value as a hex-encoded string
    #
    # @return [String] this file's SHA-1 hash value as a hex-encoded string
    def sha1_hash
        @sha1_hash ||= Digest::SHA1.hexdigest content
    end

    # Returns this file's full path in an Amazon S3 bucket
    #
    # @return [String] this file's full path in an Amazon S3 bucket
    def s3_path
        @s3_path ||= s3_prefix + "/" + sha1_hash[0..1] + "/" + sha1_hash[2..-1]
    end

    # Determines whether this file already exists in the specified bucket
    #
    # @param bucket [AWS::S3::Bucket] an Amazon S3 bucket
    def exists_in? bucket
        # TODO: Make sure that MD5 hashes match
        object = bucket.objects[s3_path]
        object.exists?
    end

    # Uploads this file to an Amazon S3 bucket unless it already exists.
    #
    # This method streams the file to Amazon S3 in chunks. If passed a block,
    # the method will yield the number of bytes it has uploaded until the
    # transfer is complete.
    #
    # @param bucket [AWS::S3::Bucket] an Amazon S3 bucket
    # @yieldparam bytes [Fixnum] the number of bytes in the last chunk that was
    #                            uploaded to Amazon S3
    def upload_to bucket
        @object = bucket.objects[s3_path]

        if @object.exists?
            yield size if block_given?
        else
            file = File.new(path, "r")
            @object.write(:content_md5 => md5_hash,
                          :content_type => mime_type,
                          :content_length => size) do |buffer,bytes|
                remaining = file.size - file.pos
                length = (remaining < bytes) ? remaining : bytes
                buffer.write(file.read(bytes))
                yield length if block_given?
            end
            file.close
        end
    end

    # Performs a HEAD request against this object and returns an object with
    # useful information about it
    #
    # This information includes the following.
    #
    # - metadata (hash of user-supplied key-value pairs)
    # - content_length (integer, number of bytes)
    # - content_type (as sent to S3 when uploading the object)
    # - etag (typically the object's MD5)
    # - server_side_encryption (the algorithm used to encrypt the object on the server side, e.g. :aes256)
    #
    # @return a head object response with metadata, content_length,
    #         content_type, etag, and server_side_encryption.
    def head
        @object.head
    end

    attr_reader :path, :size, :tags
end
