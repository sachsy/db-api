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

