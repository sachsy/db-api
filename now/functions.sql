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

