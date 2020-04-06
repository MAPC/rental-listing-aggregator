-- This updates the target tables to have appropriate metadata
-- after running a pg_restore into a fresh database
-- psql -h 127.0.0.1 -d rental-listing-aggregator -U rental-listing-aggregator -c "CREATE EXTENSION postgis;"
-- pg_restore -d rental-listing-aggregator -h 127.0.0.1 -j 2 -O -x --no-data-for-failed-tables -n public -t listings -t sources -t surveys -U rental-listing-aggregator apps.dump

CREATE SEQUENCE surveys_id_seq;
ALTER TABLE surveys ALTER id SET DEFAULT NEXTVAL('surveys_id_seq');
SELECT SETVAL('surveys_id_seq', (SELECT MAX(id) + 1 FROM surveys));
ALTER TABLE surveys ADD PRIMARY KEY (id);
ALTER TABLE sources ADD PRIMARY KEY (id);
CREATE INDEX id_pkey ON listings (id);
