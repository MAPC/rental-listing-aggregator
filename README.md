# RentalGhost

![Ghost Emoji Picture](https://github.com/MAPC/rental-listing-aggregator/blob/master/ghost.png?raw=true)

RentGhost is an open rental listing aggregator that schedules sampling crawls across multiple rental posting services. Eventually, the project intends to implement machine learning. 

Dependencies:
- Redis
- Postgres+Postgis

Getting started:
 - `bundle install`
 - `psql createdb craigslistscrape`
 - `export SINATRA_DB=postgis://yourusername@yourhost/yourdatabase`
 - `rake db:migrate`

To set up the worker process:
`QUEUE=* rake resque:work`

To start up the app:
`shotgun app.rb`

Note:
If you have an issue with dotenv/eventmachine gems, try:
`bundle config build.eventmachine --with-cppflags=-I/usr/local/opt/openssl/include`

