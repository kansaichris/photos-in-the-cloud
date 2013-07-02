class Image
    def initialize path
        @path = path
        @size = File.size(path)
    end

    # The prefix to use when storing the file in an Amazon S3 bucket
    def s3_prefix
        "objects"
    end

    def content
        @content ||= File.read(path, size)
    end

    # Open a file & determine its MIME type by reading its magic header
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

    def md5_hash
        @md5_hash ||= Digest::MD5.base64digest content
    end

    def sha1_hash
        @sha1_hash ||= Digest::SHA1.hexdigest content
    end

    def s3_path
        @s3_path ||= s3_prefix + "/" + sha1_hash[0..1] + "/" + sha1_hash[2..-1]
    end

    def upload_to bucket
        @object = bucket.objects[s3_path]

        if @object.exists?
            puts "#{path} already exists at #{@object.public_url}."
        else
            puts "Uploading #{path} to #{@object.public_url}..."
            @object.write(:file => path,
                          :content_md5 => md5_hash,
                          :content_type => mime_type)
            puts "Done."
        end
    end

    attr_reader :path, :size
end
