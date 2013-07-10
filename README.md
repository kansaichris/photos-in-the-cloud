# Amazon S3 Photo Management Tools

1. [Overview](#overview)
2. [Current Features](#current-features-version-050)
3. [Planned Features](#planned-features)
4. [FAQ](#faq)

## Overview

I started this project as a simple Ruby script to upload files to Amazon Simple Storage Service (S3) because I wanted a transparent way to manage a photo collection backed by cloud storage. There are a number of popular photo-sharing websites on the Internet today, but I'm primarily interested in streamlined photo *storage* that allows you to

- only pay for the resources that you use
- quickly find and download local copies of photos that match a wide variety of criteria
- synchronize local folders with your cloud storage
- eliminate duplicate photos
- easily store and retrieve metadata, including comments

I haven't found a program or service with all of these features, so I decided to try to write my own. Progress may be slow as this is still just a hobby project for me, but in the meantime I hope that someone else will find it to be useful, either as a tool or as a reference point for learning how to use the Amazon S3 REST API with Ruby.

## Current Features (version 0.5.0)

- Upload individual photos named with SHA-1 hashes (like Git)
- Recursively upload all photos in a directory
- Display a progress meter during uploads

## Planned Features

See [TODO.md](TODO.md).

## Documentation

- [API](http://chris-frederick.github.io/photos-in-the-cloud/doc/)

## FAQ

### 1. Why Ruby?

I would eventually like to run these tools on a server somewhere for remote access and sharing purposes. Ruby is a popular language for server-side programs and has a number of robust libraries available for it (such as [Sinatra][sinatra]). Ideally you should be able to run these tools on a cloud platform like Heroku, if you so desire.

  [sinatra]: http://www.sinatrarb.com/

I also must admit that I have wanted to learn how to program in Ruby for a long time, and this project seemed like a good excuse to do so.

### 2. What version of Ruby has this project been tested on?

1.9.3.

### 3. What do this project's version numbers mean?

This project uses [Semantic Versioning][semver]. I encourage you to read the linked specifications to learn more, but I have provided a brief summary below for convenience.

> Once you identify your public API, you communicate changes to it with specific increments to your version number. Consider a version format of X.Y.Z (Major.Minor.Patch). Bug fixes not affecting the API increment the patch version, backwards compatible API additions/changes increment the minor version, and backwards incompatible API changes increment the major version.

  [semver]: http://semver.org/
