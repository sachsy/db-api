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

