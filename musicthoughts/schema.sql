SET client_min_messages TO ERROR;
SET client_encoding = 'UTF8';
DROP SCHEMA IF EXISTS musicthoughts CASCADE;
BEGIN;

CREATE SCHEMA musicthoughts;
SET search_path = musicthoughts;

-- composing, performing, listening, etc
CREATE TABLE musicthoughts.categories (
	id serial primary key,
	en text,
	es text,
	fr text,
	de text,
	it text,
	pt text,
	ja text,
	zh text,
	ar text,
	ru text
);

-- users who submit a thought
CREATE TABLE musicthoughts.contributors (
	id serial primary key,
	person_id integer NOT NULL UNIQUE REFERENCES peeps.people(id),
	url varchar(255),  -- TODO: use peeps.people.urls.main
	place varchar(255)
);

-- famous people who said the thought
CREATE TABLE musicthoughts.authors (
	id serial primary key,
	name varchar(127) UNIQUE,
	url varchar(255)
);

-- quotes
CREATE TABLE musicthoughts.thoughts (
	id serial primary key,
	approved boolean default false,
	author_id integer not null REFERENCES musicthoughts.authors(id) ON DELETE RESTRICT,
	contributor_id integer not null REFERENCES musicthoughts.contributors(id) ON DELETE RESTRICT,
	created_at date not null default CURRENT_DATE,
	as_rand boolean not null default false, -- best-of to include in random selection
	source_url varchar(255),  -- where quote was found
	en text,
	es text,
	fr text,
	de text,
	it text,
	pt text,
	ja text,
	zh text,
	ar text,
	ru text
);

CREATE TABLE musicthoughts.categories_thoughts (
	thought_id integer not null REFERENCES musicthoughts.thoughts(id) ON DELETE CASCADE,
	category_id integer not null REFERENCES musicthoughts.categories(id) ON DELETE RESTRICT,
	PRIMARY KEY (thought_id, category_id)
);
CREATE INDEX ctti ON musicthoughts.categories_thoughts(thought_id);
CREATE INDEX ctci ON musicthoughts.categories_thoughts(category_id);

COMMIT;

----------------------------------------
--------------- VIEWS FOR JSON RESPONSES:
----------------------------------------

DROP VIEW IF EXISTS musicthoughts.authors_view CASCADE;
CREATE VIEW musicthoughts.authors_view AS
	SELECT id, name,
		(SELECT COUNT(*) FROM musicthoughts.thoughts
			WHERE author_id=musicthoughts.authors.id AND approved IS TRUE) AS howmany
		FROM musicthoughts.authors WHERE id IN
			(SELECT author_id FROM musicthoughts.thoughts WHERE approved IS TRUE)
		ORDER BY howmany DESC, name ASC;

DROP VIEW IF EXISTS musicthoughts.contributors_view CASCADE;
CREATE VIEW musicthoughts.contributors_view AS
	SELECT contributors.id, peeps.people.name,
		(SELECT COUNT(*) FROM musicthoughts.thoughts
			WHERE contributor_id=musicthoughts.contributors.id AND approved IS TRUE) AS howmany
		FROM musicthoughts.contributors, peeps.people WHERE musicthoughts.contributors.person_id=peeps.people.id
		AND musicthoughts.contributors.id IN
			(SELECT contributor_id FROM musicthoughts.thoughts WHERE approved IS TRUE)
		ORDER BY howmany DESC, name ASC;

-- PARAMS: lang, OPTIONAL: thoughts.id, search term, limit
CREATE OR REPLACE FUNCTION musicthoughts.thought_view(char(2), integer, varchar, integer) RETURNS text AS $$
DECLARE
	qry text;
BEGIN
	qry := FORMAT ('SELECT id, source_url, %I AS thought,
		(SELECT row_to_json(a) FROM
			(SELECT id, name FROM musicthoughts.authors WHERE musicthoughts.thoughts.author_id=musicthoughts.authors.id) a) AS author,
		(SELECT row_to_json(c) FROM
			(SELECT contributors.id, peeps.people.name FROM musicthoughts.contributors
				INNER JOIN peeps.people ON musicthoughts.contributors.person_id=peeps.people.id
				WHERE musicthoughts.thoughts.contributor_id=musicthoughts.contributors.id) c) AS contributor,
		(SELECT json_agg(ct) FROM
			(SELECT categories.id, categories.%I AS category
				FROM musicthoughts.categories, musicthoughts.categories_thoughts
				WHERE musicthoughts.categories_thoughts.category_id=musicthoughts.categories.id
				AND musicthoughts.categories_thoughts.thought_id=musicthoughts.thoughts.id) ct) AS categories
		FROM musicthoughts.thoughts WHERE approved IS TRUE', $1, $1);
	IF $2 IS NOT NULL THEN
		qry := qry || FORMAT (' AND id = %s', $2);
	END IF;
	IF $3 IS NOT NULL THEN
		qry := qry || FORMAT (' AND %I ILIKE %L', $1, $3);
	END IF;
	qry := qry || ' ORDER BY id DESC';
	IF $4 IS NOT NULL THEN
		qry := qry || FORMAT (' LIMIT %s', $4);
	END IF;
	RETURN qry;
END;
$$ LANGUAGE plpgsql;

----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

-- NOTE: all queries only show where thoughts.approved IS TRUE
-- When building manager API, I will add unapproved thoughts function

-- PARAMS: -none-
CREATE OR REPLACE FUNCTION musicthoughts.languages(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := '["en","es","fr","de","it","pt","ja","zh","ar","ru"]';
END;
$$ LANGUAGE plpgsql;


-- PARAMS: lang
CREATE OR REPLACE FUNCTION musicthoughts.all_categories(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	EXECUTE FORMAT ('SELECT json_agg(r) FROM (SELECT id, %I AS category, 
		(SELECT COUNT(thoughts.id) FROM categories_thoughts, thoughts
			WHERE category_id=categories.id
			AND thoughts.id=categories_thoughts.thought_id AND thoughts.approved IS TRUE)
			AS howmany FROM categories ORDER BY id) r', $1) INTO js;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: lang, category_id
CREATE OR REPLACE FUNCTION musicthoughts.category(char(2), integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	qry text;
BEGIN
	qry := FORMAT ('SELECT id, %I AS category, (SELECT json_agg(t) FROM
		(SELECT id, %I AS thought, (SELECT row_to_json(a) FROM (SELECT id, name
			FROM authors WHERE thoughts.author_id=authors.id) a) AS author
		FROM thoughts, categories_thoughts
		WHERE category_id=categories.id AND thought_id=thoughts.id AND approved IS TRUE
		ORDER BY id DESC) t) AS thoughts
		FROM categories WHERE id = %s', $1, $1, $2);
	status := 200;
	EXECUTE 'SELECT row_to_json(r) FROM (' || qry || ') r' INTO js;
	IF js IS NULL THEN

	status := 404;
	js := '{}';

	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: top limit  (NULL for all)
CREATE OR REPLACE FUNCTION musicthoughts.top_authors(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM authors_view LIMIT $1) r;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: lang, author id
CREATE OR REPLACE FUNCTION musicthoughts.get_author(char(2), integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	qry text;
BEGIN
	-- TODO: silly that I'm re-querying for author inside thought subselect
	-- Find way to re-use id, name from top of query, outside subselect
	qry := FORMAT ('SELECT id, name, (SELECT json_agg(t) FROM
		(SELECT id, %I AS thought, (SELECT row_to_json(a) FROM
			(SELECT id, name FROM authors WHERE thoughts.author_id=authors.id) a)
			AS author FROM thoughts
			WHERE author_id=authors.id AND approved IS TRUE
			ORDER BY id DESC) t) AS thoughts
		FROM authors WHERE id = %s', $1, $2);
	status := 200;
	EXECUTE 'SELECT row_to_json(r) FROM (' || qry || ') r' INTO js;
	IF js IS NULL THEN

	status := 404;
	js := '{}';

	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: top limit  (NULL for all)
CREATE OR REPLACE FUNCTION musicthoughts.top_contributors(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM contributors_view LIMIT $1) r;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: lang, contributor id
CREATE OR REPLACE FUNCTION musicthoughts.get_contributor(char(2), integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	qry text;
BEGIN
	qry := FORMAT ('SELECT contributors.id, peeps.people.name, (SELECT json_agg(t) FROM
		(SELECT id, %I AS thought, (SELECT row_to_json(a) FROM (SELECT id, name
				FROM authors WHERE thoughts.author_id=authors.id) a) AS author
			FROM thoughts
			WHERE contributor_id=contributors.id AND approved IS TRUE
			ORDER BY id DESC) t) AS thoughts
		FROM contributors, peeps.people
		WHERE contributors.person_id=peeps.people.id AND contributors.id = %s', $1, $2);
	status := 200;
	EXECUTE 'SELECT row_to_json(r) FROM (' || qry || ') r' INTO js;
	IF js IS NULL THEN

	status := 404;
	js := '{}';

	END IF;
END;
$$ LANGUAGE plpgsql;


-- ALL APPROVED thoughts, in this language: (just id, thought, author)
-- PARAMS: lang
CREATE OR REPLACE FUNCTION musicthoughts.approved_thoughts(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	EXECUTE format ('SELECT json_agg(r) FROM (SELECT
		thoughts.id, thoughts.%I AS thought, authors.name AS author
		FROM musicthoughts.thoughts
		JOIN musicthoughts.authors
		ON musicthoughts.thoughts.author_id=musicthoughts.authors.id
		WHERE approved IS TRUE
		ORDER BY thoughts.id) r', $1) INTO js;
END;
$$ LANGUAGE plpgsql;


-- ALL RANDOM thoughts, in this language: (just id, thought, author)
-- PARAMS: lang
CREATE OR REPLACE FUNCTION musicthoughts.random_thoughts(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	EXECUTE format ('SELECT json_agg(r) FROM (SELECT
		thoughts.id, thoughts.%I AS thought, authors.name AS author
		FROM musicthoughts.thoughts
		JOIN musicthoughts.authors
		ON musicthoughts.thoughts.author_id=musicthoughts.authors.id
		WHERE as_rand IS TRUE
		ORDER BY thoughts.id) r', $1) INTO js;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: lang
CREATE OR REPLACE FUNCTION musicthoughts.random_thought(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	EXECUTE 'SELECT row_to_json(r) FROM ('
		|| thought_view($1, (SELECT id FROM thoughts WHERE as_rand IS TRUE
			LIMIT 1 OFFSET (SELECT floor(random() *
					(SELECT COUNT(*) FROM thoughts WHERE as_rand IS TRUE)))),
			NULL, NULL)
		|| ') r' INTO js;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: lang, thought id
CREATE OR REPLACE FUNCTION musicthoughts.get_thought(char(2), integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	EXECUTE 'SELECT row_to_json(r) FROM (' || thought_view($1, $2, NULL, NULL) || ') r' INTO js;
	IF js IS NULL THEN

	status := 404;
	js := '{}';

	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: lang, newest limit (NULL for all)
CREATE OR REPLACE FUNCTION musicthoughts.new_thoughts(char(2), integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	EXECUTE 'SELECT json_agg(r) FROM (' || thought_view($1, NULL, NULL, $2) || ') r' INTO js;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: lang, search term
CREATE OR REPLACE FUNCTION musicthoughts.search(char(2), text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	q text;
	auth json;
	cont json;
	cats json;
	thts json;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	IF LENGTH(regexp_replace($2, '\s', '', 'g')) < 2 THEN
		RAISE 'search term too short';
	END IF;
	q := concat('%', btrim($2, E'\r\n\t '), '%');
	SELECT json_agg(r) INTO auth FROM
		(SELECT * FROM authors_view WHERE name ILIKE q) r;
	SELECT json_agg(r) INTO cont FROM
		(SELECT * FROM contributors_view WHERE name ILIKE q) r;
	EXECUTE FORMAT ('SELECT json_agg(r) FROM (SELECT id, %I AS category
		FROM categories WHERE %I ILIKE %L ORDER BY id) r',
		$1, $1, q) INTO cats;
	EXECUTE 'SELECT json_agg(r) FROM ('
		|| thought_view($1, NULL, q, NULL) || ') r' INTO thts;
	status := 200;
	js := json_build_object(
		'authors', auth,
		'contributors', cont,
		'categories', cats,
		'thoughts', thts);

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


-- PARAMS:
-- $1 = lang code
-- $2 = thought
-- $3 = contributor name
-- $4 = contributor email
-- $5 = contributor url
-- $6 = contributor place
-- $7 = author name
-- $8 = source url
-- $9 = array of category ids
-- Having ordered params is a drag, so is accepting then unnesting JSON with specific key names.
-- Returns simple hash of ids, since thought is unapproved and untranslated, no view yet.
CREATE OR REPLACE FUNCTION musicthoughts.add_thought(
	char(2), text, text, text, text, text, text, text, integer[],
	OUT status smallint, OUT js json) AS $$
DECLARE
	pers_id integer;
	cont_id integer;
	auth_id integer;
	newt_id integer;
	cat_id integer;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	SELECT id INTO pers_id FROM peeps.person_create($3, $4);
	SELECT id INTO cont_id FROM contributors WHERE person_id = pers_id;
	IF cont_id IS NULL THEN
		INSERT INTO contributors (person_id, url, place) VALUES (pers_id, $5, $6)
			RETURNING id INTO cont_id;
	END IF;
	SELECT id INTO auth_id FROM authors WHERE name ILIKE btrim($7, E'\r\n\t ');
	IF auth_id IS NULL THEN
		INSERT INTO authors (name) VALUES ($7) RETURNING id INTO auth_id;
	END IF;
	EXECUTE format ('INSERT INTO thoughts (author_id, contributor_id, source_url, %I)'
		|| ' VALUES (%L, %L, %L, %L) RETURNING id', $1, auth_id, cont_id, $8, $2)
		INTO newt_id;
	IF $9 IS NOT NULL THEN
		FOREACH cat_id IN ARRAY $9 LOOP
			INSERT INTO categories_thoughts VALUES (newt_id, cat_id);
		END LOOP;
	END IF;
	status := 200;
	js := json_build_object(
		'thought', newt_id,
		'contributor', cont_id,
		'author', auth_id);

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

