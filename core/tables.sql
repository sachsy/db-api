SET client_min_messages TO ERROR;
SET client_encoding = 'UTF8';
DROP SCHEMA IF EXISTS core CASCADE;
BEGIN;

CREATE SCHEMA core;
SET search_path = core;

CREATE TABLE currencies (
	code character(3) NOT NULL primary key,
	name text
);

CREATE TABLE currency_rates (
	code character(3) NOT NULL REFERENCES currencies(code),
	day date not null default CURRENT_DATE,
	rate numeric,
	PRIMARY KEY (code, day)
);

CREATE TABLE translation_files (
	id serial primary key,
	filename varchar(64) not null unique,
	raw text,
	template text
);

CREATE TABLE translations (
	code char(8) primary key,
	file_id integer REFERENCES translation_files(id),
	sortid integer,
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

COMMIT;

