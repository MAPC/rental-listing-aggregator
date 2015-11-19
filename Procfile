web: bundle exec thin start -p $PORT
resque: env TERM_CHILD=1 bundle exec rake resque:work TERM_CHILD=1 QUEUE='*'