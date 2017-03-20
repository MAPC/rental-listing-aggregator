SHELL= /bin/bash

setup_db:
	docker-compose run ruby bundle exec rake db:setup

export_db:
	docker-compose exec db sh -c 'pg_dump craigslistscrape' > db_dumps/db_$(shell date +"%Y%m%d%H%M").sql

geojson:
	docker-compose exec db sh -c 'psql craigslistscrape -t -P pager=off -c "SELECT row_to_json(featcoll) FROM (SELECT '\''FeatureCollection'\'' As type, array_to_json(array_agg(feat)) As features FROM (SELECT '\''Feature'\'' As type, ST_AsGeoJSON(tbl.location)::json As geometry, row_to_json((SELECT l FROM (SELECT id,ask,bedrooms,title,address,posting_date,created_at,updated_at,payload,source_id,survey_id) As l)) As properties FROM listings As tbL) As feat) As featcoll;"'

scrape:
	docker-compose run ruby bundle exec rake scraper:scrape
