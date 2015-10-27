SET client_min_messages TO ERROR;
SET client_encoding = 'UTF8';
DROP SCHEMA IF EXISTS core CASCADE;
BEGIN;

CREATE SCHEMA core;
SET search_path = core;

CREATE TABLE core.currencies (
	code character(3) NOT NULL primary key,
	name text
);

CREATE TABLE core.currency_rates (
	code character(3) NOT NULL REFERENCES core.currencies(code),
	day date not null default CURRENT_DATE,
	rate numeric,
	PRIMARY KEY (code, day)
);

CREATE TABLE core.translation_files (
	id serial primary key,
	filename varchar(64) not null unique,
	raw text,
	template text
);

CREATE TABLE core.translation_orders (
	id integer not null primary key,
	file_id integer REFERENCES core.translation_files(id),
	lang char(2),
	created_at date NOT NULL DEFAULT CURRENT_DATE,
	finished_at date
);

CREATE TABLE core.translations (
	code char(8) primary key,
	file_id integer REFERENCES core.translation_files(id),
	sortid integer,
	en text,
	es text,
	fr text,
	pt text,
	zh text
);

COMMIT;

