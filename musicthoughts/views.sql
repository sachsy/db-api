----------------------------------------
--------------- VIEWS FOR JSON RESPONSES:
----------------------------------------

DROP VIEW IF EXISTS category_view CASCADE;
DROP VIEW IF EXISTS author_view CASCADE;
DROP VIEW IF EXISTS contributor_view CASCADE;
DROP VIEW IF EXISTS thought_view CASCADE;

DROP VIEW IF EXISTS authors_view CASCADE;
CREATE VIEW authors_view AS
	SELECT id, name,
		(SELECT COUNT(*) FROM thoughts
			WHERE author_id=authors.id AND approved IS TRUE) AS howmany
		FROM authors WHERE id IN
			(SELECT author_id FROM thoughts WHERE approved IS TRUE)
		ORDER BY howmany DESC, name ASC;

DROP VIEW IF EXISTS contributors_view CASCADE;
CREATE VIEW contributors_view AS
	SELECT contributors.id, peeps.people.name,
		(SELECT COUNT(*) FROM thoughts
			WHERE contributor_id=contributors.id AND approved IS TRUE) AS howmany
		FROM contributors, peeps.people WHERE contributors.person_id=peeps.people.id
		AND contributors.id IN
			(SELECT contributor_id FROM thoughts WHERE approved IS TRUE)
		ORDER BY howmany DESC, name ASC;

-- PARAMS: lang, OPTIONAL: thoughts.id, search term, limit
CREATE FUNCTION thought_view(char(2), integer, varchar, integer) RETURNS text AS $$
DECLARE
	qry text;
BEGIN
	qry := FORMAT ('SELECT id, source_url, %I AS thought,
		(SELECT row_to_json(a) FROM
			(SELECT id, name FROM authors WHERE thoughts.author_id=authors.id) a) AS author,
		(SELECT row_to_json(c) FROM
			(SELECT contributors.id, peeps.people.name FROM contributors
				LEFT JOIN peeps.people ON contributors.person_id=peeps.people.id
				WHERE thoughts.contributor_id=contributors.id) c) AS contributor,
		(SELECT json_agg(ct) FROM
			(SELECT categories.id, categories.%I AS category
				FROM categories, categories_thoughts
				WHERE categories_thoughts.category_id=categories.id
				AND categories_thoughts.thought_id=thoughts.id) ct) AS categories
		FROM thoughts WHERE approved IS TRUE', $1, $1);
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

