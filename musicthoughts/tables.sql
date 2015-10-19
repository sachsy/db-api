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

