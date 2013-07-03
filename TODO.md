# TODO

## Basic Operations

- Download photos by size, date, and metadata
- Sync "smart directories"
- Automatically generate thumbnails
- Use Zlib compression


## Amazon Web Services

- Create a new bucket if necessary
- Automatically detect and use the appropriate region for a specified bucket
- Use [Multipart Upload][multipart] for files larger than 100 MB (or some other acceptable threshold for this program's memory footprint).
- Use [Reduced Redundancy Storage][rrs] for image thumbnails
- (Optionally) use [Amazon Glacier][glacier] to store the original (or infrequently viewed) image files
- Provide an estimate of monthly storage costs
- Disallow files larger than 5 TB

  [multipart]: http://docs.amazonwebservices.com/AmazonS3/latest/dev/UploadingObjects.html
  [rrs]: http://aws.amazon.com/s3/faqs/#What_is_RRS
  [glacier]: http://aws.amazon.com/glacier/

## Metadata

- Tag photos
- Rate photos
- Comment on photos
- Download photo metadata
- Index photo metadata

## Web Interface

- Provide a web-based interface for sharing photos with friends and family