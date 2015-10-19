SET client_min_messages TO ERROR;
DROP SCHEMA IF EXISTS woodegg CASCADE;
CREATE SCHEMA woodegg;

SET search_path = woodegg;
BEGIN;

CREATE TABLE woodegg.researchers (
	id serial PRIMARY KEY,
	person_id integer not null UNIQUE REFERENCES peeps.people(id),
	bio text
);

CREATE TABLE woodegg.writers (
	id serial PRIMARY KEY,
	person_id integer not null UNIQUE REFERENCES peeps.people(id),
	bio text
);

CREATE TABLE woodegg.editors (
	id serial PRIMARY KEY,
	person_id integer not null UNIQUE REFERENCES peeps.people(id),
	bio text
);

CREATE TABLE woodegg.customers (
	id serial PRIMARY KEY,
	person_id integer not null UNIQUE REFERENCES peeps.people(id)
);

CREATE TABLE woodegg.topics (
	id serial PRIMARY KEY,
	topic varchar(32) not null CHECK (length(topic) > 0)
);

CREATE TABLE woodegg.subtopics (
	id serial PRIMARY KEY,
	topic_id integer not null REFERENCES woodegg.topics(id),
	subtopic varchar(64) not null CHECK (length(subtopic) > 0)
);

CREATE TABLE woodegg.template_questions (
	id serial PRIMARY KEY,
	subtopic_id integer not null REFERENCES woodegg.subtopics(id),
	question text
);
CREATE INDEX tqti ON template_questions(subtopic_id);

CREATE TABLE woodegg.questions (
	id serial PRIMARY KEY,
	template_question_id integer not null REFERENCES woodegg.template_questions(id),
	country char(2) not null REFERENCES peeps.countries(code),
	question text
);
CREATE INDEX qtqi ON questions(template_question_id);

CREATE TABLE woodegg.answers (
	id serial PRIMARY KEY,
	question_id integer not null REFERENCES woodegg.questions(id),
	researcher_id integer not null REFERENCES woodegg.researchers(id),
	started_at timestamp(0) with time zone,
	finished_at timestamp(0) with time zone,
	answer text,
	sources text
);
CREATE INDEX anqi ON answers(question_id);
CREATE INDEX anri ON answers(researcher_id);

CREATE TABLE woodegg.books (
	id serial PRIMARY KEY,
	country char(2) not null REFERENCES peeps.countries(code),
	code char(6) not null UNIQUE,
	title text,
	pages integer,
	isbn char(13),
	asin char(10),
	leanpub varchar(30),
	apple integer,
	salescopy text,
	credits text,
	available boolean
);

CREATE TABLE woodegg.books_writers (
	book_id integer not null REFERENCES woodegg.books(id),
	writer_id integer not null REFERENCES woodegg.writers(id),
	PRIMARY KEY (book_id, writer_id)
);

CREATE TABLE woodegg.books_researchers (
	book_id integer not null references books(id),
	researcher_id integer not null references researchers(id),
	PRIMARY KEY (book_id, researcher_id)
);

CREATE TABLE woodegg.books_customers (
	book_id integer not null references books(id),
	customer_id integer not null references customers(id),
	PRIMARY KEY (book_id, customer_id)
);

CREATE TABLE woodegg.books_editors (
	book_id integer not null REFERENCES woodegg.books(id),
	editor_id integer not null REFERENCES woodegg.editors(id),
	PRIMARY KEY (book_id, editor_id)
);

CREATE TABLE woodegg.essays (
	id serial PRIMARY KEY,
	question_id integer not null REFERENCES woodegg.questions(id),
	writer_id integer not null REFERENCES woodegg.writers(id),
	book_id integer not null REFERENCES woodegg.books(id),
	editor_id integer REFERENCES woodegg.writers(id),
	started_at timestamp(0) with time zone,
	finished_at timestamp(0) with time zone,
	edited_at timestamp(0) with time zone,
	content text,
	edited text
);
CREATE INDEX esqi ON essays(question_id);
CREATE INDEX esbi ON essays(book_id);

CREATE TABLE woodegg.tags (
	id serial PRIMARY KEY,
	name varchar(16) UNIQUE
);

CREATE TABLE woodegg.tidbits (
	id serial PRIMARY KEY,
	created_at date,
	created_by varchar(16),
	headline varchar(127),
	url text,
	intro text,
	content text
);

CREATE TABLE woodegg.tags_tidbits (
	tag_id integer not null REFERENCES woodegg.tags(id) ON DELETE CASCADE,
	tidbit_id integer not null REFERENCES woodegg.tidbits(id) ON DELETE CASCADE,
	PRIMARY KEY (tag_id, tidbit_id)
);

CREATE TABLE woodegg.questions_tidbits (
	question_id integer not null REFERENCES woodegg.questions(id) ON DELETE CASCADE,
	tidbit_id integer not null REFERENCES woodegg.tidbits(id) ON DELETE CASCADE,
	PRIMARY KEY (question_id, tidbit_id)
);

CREATE TABLE woodegg.uploads (
	id serial PRIMARY KEY,
	created_at date NOT NULL DEFAULT CURRENT_DATE,
	researcher_id integer not null REFERENCES woodegg.researchers(id),
	country char(2) not null REFERENCES peeps.countries(code),
	their_filename text not null,
	our_filename text not null,
	mime_type varchar(32),
	bytes integer,
	duration varchar(7), -- h:mm:ss
	uploaded char(1) NOT NULL DEFAULT 'n',
	status varchar(4) default 'new',
	notes text,
	transcription text
);

CREATE TABLE woodegg.test_essays (
	id serial PRIMARY KEY,
	person_id integer not null REFERENCES peeps.people(id),
	country char(2) not null REFERENCES peeps.countries(code),
	question_id integer REFERENCES woodegg.questions(id),
	started_at timestamp(0) with time zone,
	finished_at timestamp(0) with time zone,
	content text,
	notes text
);

COMMIT;

