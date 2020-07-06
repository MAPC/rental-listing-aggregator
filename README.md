# Rentscape

Rentscape is an open rental listing aggregator that schedules sampling crawls across multiple rental posting services. Eventually, the project intends to implement machine learning.

## Install Steps

1. Setup `database.yml`
2. `rvm install 2.7.1`
3. `gem install bundler`
4. `bundle install`
5. `bundle exec rake db:setup`

Dependencies:
- Docker
- Make

The application consists of a ruby script (the scraper) coupled with a PostGIS backend database. When the scraper is run, it queries the `sources` table in the PostGIS DB for a list of sources. For each source, it instantiates the class named in the `script` column, and attempts to run the `crawl` method on that class.

Crawl methods write their results to the `listings` table in the DB.

This application is containerized, with a `ruby` container for running the actual scraper and associated utility operations, and a `db` container holding the PostGIS database. The `ruby` container will run once and exit for each command, the `db` container should persist.

The `Makefile` contains command syntax for initalizing the database, running the scraper, exporting a backup of the full DB as SQL, and exporting the listings table to geoJSON.

Configuration
---
- Configure `database.yml` and `docker-compose.yml` for your environment
    - Copy `database.example.yml` to `database.yml`
For production:
    - In `database.yml` and `docker-compose.production.yml` set a database password on the production environment (and optionally in development)
- To limit the number of queries you're making (say, during testing), set the `MAX_RESULTS` environment variable on the `ruby`
container in `docker-compose.yml`
- Localize the configuration to your area via settings in `docker-compose.yml`:
    - Set `CRAIGSLIST_URL` to the base URL for your locality's Craigslist site
    - Set `PADMAPPER_MAX_LAT`, `PADMAPPER_MIN_LON` etc. to specify the bounding box for padmapper results.
- We keep a backup of our production congfiguration at `smb://data-001/Public/DataServices/Projects/Current_Projects/rental_listings_research/Documentation/docker-compose.production.yml.bak`

To schedule a regular CRON job without Docker insert something like this in your crontab after typing `crontab -e`:
`3 0 * * 3  cd /opt/rental-listing-aggregator/current && RACK_ENV=production /usr/share/rvm/wrappers/ruby-2.4.10/rake scraper:scrape 2>&1 | /usr/bin/logger -t rental_listing_scraper`

You also need to make sure you have configured your system environment variables. Potentially in /etc/environment.

```
CRAIGSLIST_URL='https://boston.craigslist.org'
PADMAPPER_MAX_LON=-70.55015359141407
PADMAPPER_MAX_LAT=42.82800417471581
PADMAPPER_MIN_LON=-71.70406136729298
PADMAPPER_MIN_LAT=41.98895821456554
SENTRY_DSN: ''
MAILGUN_API_KEY: ''
MAILGUN_DOMAIN: ''
```

## Database Migration
To migrate from the apps database to the new Postgres 11.7 database we did

```
createuser rental-listing-aggregator -d -P -s

createdb -O rental-listing-aggregator rental-listing-aggregator

psql -h 127.0.0.1 -d rental-listing-aggregator -U rental-listing-aggregator -c "CREATE EXTENSION postgis;"

pg_restore -d rental-listing-aggregator -h 127.0.0.1 -j 2 -O -x --no-data-for-failed-tables -n public -t listings -t sources -t surveys -U rental-listing-aggregator apps.dump

psql -h 127.0.0.1 -d rental-listing-aggregator -U rental-listing-aggregator -f after-pg_restore.sql

psql -h 127.0.0.1 -d rental-listing-aggregator -U rental-listing-aggregator -c "ALTER ROLE rental-listing-aggregator NOSUPERUSER;"
```


## Running (Old Instructions)

- `docker-compose up --build` will build the ruby container and create the database.
- `make setup-db` will create and seed the database.
- `make scrape` runs the scraper one time
- `make export-geojson` queries the `listings` table and prints the result as a timestamped geojson in the `geojson` directory
- `make export-db` exports the database to a timestmaped SQL file in the `db_dumps` directory
- To seed the database with a previously-exported DB, place the .sql or .sql.gz file in the `db_import` directory and the PostGIS container will load it when started.
