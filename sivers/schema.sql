SET client_min_messages TO ERROR;
DROP SCHEMA IF EXISTS sivers CASCADE;
BEGIN;

CREATE SCHEMA sivers;
SET search_path = sivers;

CREATE TABLE sivers.comments (
	id serial primary key,
	uri varchar(32) not null CONSTRAINT valid_uri CHECK (uri ~ '\A[a-z0-9-]+\Z'),
	person_id integer not null REFERENCES peeps.people(id) ON DELETE CASCADE,
	created_at date not null default CURRENT_DATE,
	name text CHECK (length(name) > 0),
	email text CONSTRAINT valid_email CHECK (email ~ '\A\S+@\S+\.\S+\Z'),
	html text not null CHECK (length(html) > 0)
);
CREATE INDEX comuri ON sivers.comments(uri);
CREATE INDEX compers ON sivers.comments(person_id);

CREATE TABLE sivers.tweets (
	id bigint primary key,
	entire jsonb,
	created_at timestamp(0),
	person_id integer REFERENCES peeps.people(id) ON DELETE CASCADE,
	handle varchar(15),
	message text,
	reference_id bigint,
	seen boolean
);
CREATE INDEX stpi ON sivers.tweets(person_id);
CREATE INDEX sthandle ON sivers.tweets(handle);
CREATE INDEX stseen ON sivers.tweets(seen);

COMMIT;

CREATE OR REPLACE FUNCTION comments_changed() RETURNS TRIGGER AS $$
DECLARE
	u text;
BEGIN
	IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
		u := NEW.uri;
	ELSE
		u := OLD.uri;
	END IF;
	PERFORM pg_notify('comments_changed', u);
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS comments_changed ON comments;
CREATE TRIGGER comments_changed AFTER INSERT OR UPDATE OR DELETE ON comments FOR EACH ROW EXECUTE PROCEDURE comments_changed();

----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

-- GET %r{^/comments/([0-9]+)$}
-- PARAMS: comment id
CREATE OR REPLACE FUNCTION sivers.get_comment(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM
		(SELECT *, (SELECT row_to_json(p) AS person FROM
			(SELECT * FROM peeps.person_view WHERE id=sivers.comments.person_id) p)
		FROM sivers.comments WHERE id=$1) r;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
END;
$$ LANGUAGE plpgsql;


-- POST %r{^/comments/([0-9]+)$}
-- PARAMS: uri, name, email, html
CREATE OR REPLACE FUNCTION sivers.add_comment(text, text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_uri text;
	new_name text;
	new_email text;
	new_html text;
	new_person_id integer;
	new_id integer;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	new_uri := regexp_replace(lower($1), '[^a-z0-9-]', '', 'g');
	new_name := btrim(regexp_replace($2, '[\r\n\t]', ' ', 'g'));
	new_email := btrim(lower($3));
	new_html := replace(core.escape_html(core.strip_tags(btrim($4))),
		':-)',
		'<img src="/images/icon_smile.gif" width="15" height="15" alt="smile">');
	SELECT id INTO new_person_id FROM peeps.person_create(new_name, new_email);
	INSERT INTO sivers.comments (uri, name, email, html, person_id)
		VALUES (new_uri, new_name, new_email, new_html, new_person_id)
		RETURNING id INTO new_id;
	status := 200;
	js := row_to_json(r.*) FROM sivers.comments r WHERE id = new_id;

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


-- PUT %r{^/comments/([0-9]+)$}
-- PARAMS: comments.id, JSON of values to update
CREATE OR REPLACE FUNCTION sivers.update_comment(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	PERFORM core.jsonupdate('sivers.comments', $1, $2,
		core.cols2update('sivers', 'comments', ARRAY['id','created_at']));
	status := 200;
	js := row_to_json(r.*) FROM sivers.comments r WHERE id = $1;
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


-- POST %r{^/comments/([0-9]+)/reply$}
-- PARAMS: comment_id, my reply
CREATE OR REPLACE FUNCTION sivers.reply_to_comment(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE sivers.comments SET html = CONCAT(html, '<br><span class="response">',
		replace($2, ':-)',
		'<img src="/images/icon_smile.gif" width="15" height="15" alt="smile">'),
		' -- Derek</span>') WHERE id = $1;
	status := 200;
	js := row_to_json(r.*) FROM sivers.comments r WHERE id = $1;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
END;
$$ LANGUAGE plpgsql;


-- DELETE %r{^/comments/([0-9]+)$}
-- PARAMS: comment_id
CREATE OR REPLACE FUNCTION sivers.delete_comment(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	status := 200;
	js := row_to_json(r.*) FROM sivers.comments r WHERE id = $1;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
	DELETE FROM sivers.comments WHERE id = $1;

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


-- DELETE %r{^/comments/([0-9]+)/spam$}
-- PARAMS: comment_id
CREATE OR REPLACE FUNCTION sivers.spam_comment(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	SELECT person_id INTO pid FROM sivers.comments WHERE id = $1;
	status := 200;
	js := row_to_json(r.*) FROM sivers.comments r WHERE id = $1;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
	DELETE FROM sivers.comments WHERE person_id = pid;
	DELETE FROM peeps.people WHERE id = pid;

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


-- GET '/comments/new'
-- PARAMS: -none-
CREATE OR REPLACE FUNCTION sivers.new_comments(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM
		(SELECT * FROM sivers.comments ORDER BY id DESC LIMIT 100) r;
END;
$$ LANGUAGE plpgsql;


-- GET %r{^/person/([0-9]+)/comments$}
-- PARAMS: person_id
CREATE OR REPLACE FUNCTION sivers.comments_by_person(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM
		(SELECT * FROM sivers.comments WHERE person_id=$1 ORDER BY id DESC) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: person_id
CREATE OR REPLACE FUNCTION sivers.tweets_by_person(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT id, created_at, message, reference_id
		FROM sivers.tweets WHERE person_id=$1 ORDER BY id DESC) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: tweets.id
CREATE OR REPLACE FUNCTION sivers.get_tweet(bigint,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (SELECT id, created_at, person_id, handle,
		message, reference_id, seen FROM sivers.tweets WHERE id = $1) r;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: json from Twitter API as seen here:
-- https://dev.twitter.com/rest/reference/get/statuses/mentions_timeline
CREATE OR REPLACE FUNCTION sivers.add_tweet(jsonb,
	OUT status smallint, OUT js jsonb) AS $$
DECLARE
	new_id bigint;
	new_ca timestamp(0) with time zone;
	new_handle varchar(15);
	new_pid integer;
	new_msg text;
	new_ref bigint;
	r record;
BEGIN
	new_id := ($1->>'id')::bigint;
	new_ca := $1->>'created_at';
	new_handle := $1->'user'->>'screen_name';
	new_pid := peeps.pid_for_twitter_handle(new_handle);
	new_msg := replace($1->>'text', E'\n', ' ');
	FOR r IN SELECT * FROM jsonb_array_elements($1->'entities'->'urls') LOOP
		new_msg := replace(new_msg, r.value->>'url', r.value->>'expanded_url');
	END LOOP;
	IF LENGTH($1->>'in_reply_to_status_id') > 0 THEN
		new_ref := ($1->>'in_reply_to_status_id')::bigint;
	END IF;
	INSERT INTO sivers.tweets
		(entire, id, created_at, handle, person_id, message, reference_id)
		VALUES ($1, new_id, new_ca, new_handle, new_pid, new_msg, new_ref);
	SELECT x.status, x.js INTO status, js FROM sivers.get_tweet(new_id) x;
END;
$$ LANGUAGE plpgsql;


