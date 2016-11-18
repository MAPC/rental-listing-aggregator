#!/bin/sh
PATH=/Users/mgardner/.rvm/gems/ruby-2.1.2/bin:/Users/mgardner/.rvm/gems/ruby-2.1.2@global/bin:/Users/mgardner/.rvm/rubies/ruby-2.1.2/bin:/Users/mgardner/.rvm/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/X11/bin
export SINATRA_DB=postgis://editor:XX9dPgNBEZWxxFz2Jo@db.live.mapc.org:5432/apps

irb <<EOF
require './app.rb'
Crawl.new
EOF
