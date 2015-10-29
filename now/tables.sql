SET client_min_messages TO ERROR;
DROP SCHEMA IF EXISTS now CASCADE;
BEGIN;

CREATE SCHEMA now;
SET search_path = now;

CREATE TABLE now.urls (
	id serial primary key,
	person_id integer REFERENCES peeps.people(id) ON DELETE CASCADE,
	created_at date not null default CURRENT_DATE,
	updated_at date,
	short varchar(72),
	long varchar(100) CONSTRAINT url_format CHECK (long ~ '^https?://[0-9a-zA-Z_-]+\.[a-zA-Z0-9]+')
);

COMMIT;

