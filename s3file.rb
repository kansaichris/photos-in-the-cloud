class S3File < File
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
        @md5_hash = Digest::MD5.base64digest content
    end

    def sha1_hash
        @sha1_hash = Digest::SHA1.hexdigest content
    end
end
