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
	IF js IS NULL THEN m4_NOTFOUND END IF;
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
	IF js IS NULL THEN m4_NOTFOUND END IF;
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
m4_ERRVARS
BEGIN
	status := 200;
	WITH nu AS (INSERT INTO now.urls(person_id, short)
		VALUES ($1, $2) RETURNING *)
		SELECT row_to_json(r) INTO js FROM (SELECT * FROM nu) r;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: now.urls.id
CREATE OR REPLACE FUNCTION now.delete_url(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	SELECT x.status, x.js INTO status, js FROM now.url($1) x;
	DELETE FROM now.urls WHERE id = $1;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: now.urls.id, JSON of new values
CREATE OR REPLACE FUNCTION now.update_url(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM core.jsonupdate('now.urls', $1, $2,
		core.cols2update('now', 'urls', ARRAY['id', 'created_at', 'updated_at']));
	status := 200;
	UPDATE now.urls SET updated_at=NOW() WHERE id = $1;
	js := row_to_json(r.*) FROM now.urls r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;

-- NOTE: will also use from peeps schema:
-- peeps.update_stat(id, json)
-- peeps.add_stat(person_id, name, value)

