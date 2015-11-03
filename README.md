# RentalGhost

RentGhost is an open rental listing aggregator that schedules sampling crawls across multiple rental posting services. Eventually, the project intends to implement machine learning. 

Dependencies:
- Redis
- Postgres+Postgis

Getting started:
 - `bundle install`
 - `psql createdb craigslistscrape`
 - `EXPORT SINATRA_DB=postgis://yourusername@yourhost/yourdatabase`
 - `rake db:migrate`

To set up the worker process:
`QUEUE=* rake resque:work`

To start up the app:
`shotgun app.rb`