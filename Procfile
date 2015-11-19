resque: env TERM_CHILD=1 bundle exec rake resque:work TERM_CHILD=1 QUEUE='*'
scheduler: env DYNAMIC_SCHEDULE=true bundle exec rake resque:scheduler TERM_CHILD=1 --trace