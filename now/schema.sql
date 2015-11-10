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

----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

-- now.urls missing person_id
CREATE OR REPLACE FUNCTION now.unknowns(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM
		(SELECT id, short, long FROM now.urls WHERE person_id IS NULL) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: now.urls.id
CREATE OR REPLACE FUNCTION now.url(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM now.urls r WHERE id = $1;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: now.urls.id
CREATE OR REPLACE FUNCTION now.unknown_find(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.people_view WHERE id IN
		(SELECT * FROM now.find_person($1))) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: now.urls.id, person_id
CREATE OR REPLACE FUNCTION now.unknown_assign(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	UPDATE now.urls SET person_id = $2 WHERE id = $1;
	js := row_to_json(r.*) FROM now.urls r WHERE id = $1;
END;
$$ LANGUAGE plpgsql;

