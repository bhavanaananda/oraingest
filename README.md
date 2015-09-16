# ORA: Oxford University Research Archives

[![build](https://travis-ci.org/bodleian/oraingest.svg?branch=dev)](https://travis-ci.org/bodleian/oraingest)
[![Coverage Status](https://coveralls.io/repos/bodleian/oraingest/badge.svg)](https://coveralls.io/r/bodleian/oraingest)
[![Dependency Status](https://gemnasium.com/bodleian/oraingest.svg)](https://gemnasium.com/bodleian/oraingest)
[![Code Climate](https://codeclimate.com/github/bodleian/oraingest/badges/gpa.svg)](https://codeclimate.com/github/bodleian/oraingest)
[![MIT license](http://img.shields.io/badge/license-MIT-brightgreen.svg)](https://github.com/bodleian/oraingest/blob/master/docs/LICENSE.txt)

This is a [Sufia](https://github.com/projecthydra/sufia)-based [Hydra Head](http://projecthydra.org)

# Installation

This is based on the instructions in the [Sufia README](https://github.com/projecthydra/sufia)

### Run the migrations

```
rake db:migrate
```

### Get a copy of hydra-jetty
```
rails g hydra:jetty
rake jetty:config
rake jetty:start
```

### Install Fits.sh
http://code.google.com/p/fits/downloads/list
Download a copy of fits & unpack it somewhere on your PATH.

### Start background workers
```
COUNT=4 QUEUE=* rake environment resque:work
```
See https://github.com/defunkt/resque for more options

### If you want to enable transcoding of video, instal ffmpeg version 1.0+
#### On a mac
Use homebrew:
```
brew install ffmpeg --with-libvpx --with-libvorbis
```

#### On Ubuntu Linux
See https://ffmpeg.org/trac/ffmpeg/wiki/UbuntuCompilationGuide

Testing
-------
If you are running the tests locally, you need to pass the port used by jetty
to host fedora and solr, to the environment variable JETTY_PORT. For example:

    JETTY_PORT=8080 rspec

