# Rentscape

RentGhost is an open rental listing aggregator that schedules sampling crawls across multiple rental posting services. Eventually, the project intends to implement machine learning. 

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

Running
---

- `docker-compose up --build` will build the ruby container and create the database.
- `make setup-db` will create and seed the database.
- `make scrape` runs the scraper one time
- `make export-geojson` queries the `listings` table and prints the result as a timestamped geojson in the `geojson` directory
- `make export-db` exports the database to a timestmaped SQL file in the `db_dumps` directory
- To seed the database with a previously-exported DB, place the .sql or .sql.gz file in the `db_import` directory and the PostGIS container will load it when started.
