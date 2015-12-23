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

