#!/bin/sh
irb <<EOF
require './app.rb'
Crawl.new
EOF
