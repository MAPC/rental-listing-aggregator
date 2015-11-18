web: bundle exec thin start -p $PORT -e $RACK_ENV
resque: env TERM_CHILD=1 bundle exec rake resque:work QUEUE='*' --trace
scheduler: bundle exec rake resque:scheduler --trace