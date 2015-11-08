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
	tiny varchar(24) UNIQUE,
	short varchar(72) UNIQUE,
	long varchar(100) UNIQUE CONSTRAINT url_format CHECK (long ~ '^https?://[0-9a-zA-Z_-]+\.[a-zA-Z0-9]+')
);

COMMIT;

----------------------------
----------------- FUNCTIONS:
----------------------------

-- PARAMS: now.urls.id
CREATE OR REPLACE FUNCTION now.find_person(integer) RETURNS SETOF integer AS $$
BEGIN
	RETURN QUERY SELECT p.person_id
	FROM now.urls n
	INNER JOIN peeps.urls p
	ON (regexp_replace(n.short, '/.*$', '') =
	regexp_replace(regexp_replace(regexp_replace(lower(p.url), '^https?://', ''), '^www.', ''), '/.*$', ''))
	WHERE n.id = $1;
END;
$$ LANGUAGE plpgsql;

