web: bundle exec thin start -p $PORT
resque: env TERM_CHILD=2 bundle exec rake resque:work TERM_CHILD=1 QUEUE='*'
scheduler: env DYNAMIC_SCHEDULE=true bundle exec rake resque:scheduler --trace