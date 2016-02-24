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
	short varchar(72) UNIQUE,
	long text UNIQUE CONSTRAINT url_format CHECK (long ~ '^https?://[0-9a-zA-Z_-]+\.[a-zA-Z0-9]+'),
	hash text
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

----------------------------
------------------ TRIGGERS:
----------------------------

-- everyone with a now.url will probably a public_id soon, so after 
-- insert of now.url, or update of person_id, create public_id if not there already
CREATE OR REPLACE FUNCTION now.ensure_public_id() RETURNS TRIGGER AS $$
BEGIN
	UPDATE peeps.people
		SET public_id=core.unique_for_table_field(4, 'peeps.people', 'public_id')
		WHERE id = NEW.person_id AND public_id IS NULL;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS ensure_public_id ON now.urls CASCADE;
CREATE TRIGGER ensure_public_id AFTER INSERT OR UPDATE OF person_id ON now.urls
	FOR EACH ROW EXECUTE PROCEDURE now.ensure_public_id();


CREATE OR REPLACE FUNCTION now.clean_short() RETURNS TRIGGER AS $$
BEGIN
	NEW.short = regexp_replace(NEW.short, '\s', '', 'g');
	NEW.short = regexp_replace(NEW.short, '^https?://', '');
	NEW.short = regexp_replace(NEW.short, '^www.', '');
	NEW.short = regexp_replace(NEW.short, '/$', '');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_short ON now.urls CASCADE;
CREATE TRIGGER clean_short
	BEFORE INSERT OR UPDATE OF short ON now.urls
	FOR EACH ROW EXECUTE PROCEDURE now.clean_short();


CREATE OR REPLACE FUNCTION now.clean_long() RETURNS TRIGGER AS $$
BEGIN
	NEW.long = regexp_replace(NEW.long, '\s', '', 'g');
	IF NEW.long !~ '^https?://' THEN
		NEW.long = 'http://' || NEW.long;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_long ON now.urls CASCADE;
CREATE TRIGGER clean_long
	BEFORE INSERT OR UPDATE OF long ON now.urls
	FOR EACH ROW EXECUTE PROCEDURE now.clean_long();

----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

-- now.urls with person_id
CREATE OR REPLACE FUNCTION now.knowns(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM
		(SELECT id, person_id, short FROM now.urls
			WHERE person_id IS NOT NULL ORDER BY short) r;
END;
$$ LANGUAGE plpgsql;


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
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
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
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: person_id
CREATE OR REPLACE FUNCTION now.urls_for_person(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM
		(SELECT * FROM now.urls WHERE person_id=$1 ORDER BY id) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: person_id
CREATE OR REPLACE FUNCTION now.stats_for_person(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM
		(SELECT id, statkey AS name, statvalue AS value, created_at
			FROM peeps.stats WHERE person_id=$1 AND statkey LIKE 'now-%'
			ORDER BY id) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: person_id, short
CREATE OR REPLACE FUNCTION now.add_url(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	status := 200;
	WITH nu AS (INSERT INTO now.urls(person_id, short)
		VALUES ($1, $2) RETURNING *)
		SELECT row_to_json(r) INTO js FROM (SELECT * FROM nu) r;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;


-- PARAMS: now.urls.id
CREATE OR REPLACE FUNCTION now.delete_url(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	SELECT x.status, x.js INTO status, js FROM now.url($1) x;
	DELETE FROM now.urls WHERE id = $1;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;


-- PARAMS: now.urls.id, JSON of new values
CREATE OR REPLACE FUNCTION now.update_url(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	PERFORM core.jsonupdate('now.urls', $1, $2,
		core.cols2update('now', 'urls', ARRAY['id', 'created_at', 'updated_at']));
	status := 200;
	UPDATE now.urls SET updated_at=NOW() WHERE id = $1;
	js := row_to_json(r.*) FROM now.urls r WHERE id = $1;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;

-- NOTE: will also use from peeps schema:
-- peeps.update_stat(id, json)
-- peeps.add_stat(person_id, name, value)

