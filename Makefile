setup_db:
	docker-compose run ruby bundle exec rake db:setup

export_db:

scrape:
	docker-compose run ruby ./crawl.sh
