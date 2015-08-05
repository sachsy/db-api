SET client_min_messages TO ERROR;
DROP SCHEMA IF EXISTS muckwork CASCADE;
BEGIN;

CREATE SCHEMA muckwork;
SET search_path = muckwork;

CREATE TABLE managers (
	id serial primary key,
	person_id integer not null unique REFERENCES peeps.people(id)
);

CREATE TABLE clients (
	id serial primary key,
	person_id integer not null unique REFERENCES peeps.people(id),
	currency char(3) not null DEFAULT 'USD' REFERENCES peeps.currencies(code),
	cents_balance integer not null default 0
);

CREATE TABLE workers (
	id serial primary key,
	person_id integer not null unique REFERENCES peeps.people(id),
	currency char(3) not null DEFAULT 'USD' REFERENCES peeps.currencies(code),
	millicents_per_second integer CHECK (millicents_per_second >= 0)
);

CREATE TYPE muckwork.status AS ENUM('created', 'quoted', 'approved', 'refused', 'started', 'finished');

CREATE TABLE projects (
	id serial primary key,
	client_id integer not null REFERENCES clients(id),
	title text,
	description text,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	quoted_at timestamp(0) with time zone CHECK (quoted_at >= created_at),
	approved_at timestamp(0) with time zone CHECK (approved_at >= quoted_at),
	started_at timestamp(0) with time zone CHECK (started_at >= approved_at),
	finished_at timestamp(0) with time zone CHECK (finished_at >= started_at),
	status status not null default 'created',
	quoted_currency char(3) REFERENCES peeps.currencies(code),
	quoted_cents integer CHECK (quoted_cents >= 0),
	quoted_ratetype varchar(4) CHECK (quoted_ratetype = 'fix' OR quoted_ratetype = 'time'),
	final_currency char(3) REFERENCES peeps.currencies(code),
	final_cents integer CHECK (final_cents >= 0)
);
CREATE INDEX pjci ON projects(client_id);
CREATE INDEX pjst ON projects(status);

CREATE TABLE tasks (
	id serial primary key,
	project_id integer REFERENCES projects(id),
	worker_id integer REFERENCES workers(id),
	sortid integer,
	title text,
	description text,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	claimed_at timestamp(0) with time zone CHECK (claimed_at >= created_at),
	started_at timestamp(0) with time zone CHECK (started_at >= claimed_at),
	finished_at timestamp(0) with time zone CHECK (finished_at >= started_at),
	status muckwork.status not null default 'created'
);
CREATE INDEX tpi ON tasks(project_id);
CREATE INDEX twi ON tasks(worker_id);
CREATE INDEX tst ON tasks(status);

-- TODO: notes
-- CREATE TABLE notes (
--	id serial primary key,
--	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
--	project_id integer REFERENCES projects(id),
--	task_id integer REFERENCES tasks(id),
--	manager_id integer REFERENCES managers(id),
--	client_id integer REFERENCES clients(id),
--	worker_id integer REFERENCES workers(id),
--	note text
--);
--CREATE INDEX notpi ON notes(project_id);

CREATE TABLE charges (
	id serial primary key,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	project_id integer REFERENCES projects(id),
	currency char(3) not null REFERENCES peeps.currencies(code),
	cents integer not null CHECK (cents >= 0),
	notes text
);
CREATE INDEX chpi ON charges(project_id);

CREATE TABLE payments (
	id serial primary key,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	client_id integer REFERENCES clients(id),
	currency char(3) not null REFERENCES peeps.currencies(code),
	cents integer not null CHECK (cents > 0),
	notes text
);
CREATE INDEX pyci ON payments(client_id);

CREATE TABLE worker_payments (
	id serial primary key,
	worker_id integer not null REFERENCES workers(id),
	currency char(3) not null REFERENCES peeps.currencies(code),
	cents integer CHECK (cents > 0),
	created_at date not null default CURRENT_DATE,
	notes text
);
CREATE INDEX wpwi ON worker_payments(worker_id);

CREATE TABLE worker_charges (
	id serial primary key,
	task_id integer not null REFERENCES tasks(id),
	currency char(3) not null REFERENCES peeps.currencies(code),
	cents integer not null CHECK (cents >= 0),
	payment_id integer REFERENCES worker_payments(id) -- NULL until paid
);
CREATE INDEX wcpi ON worker_charges(payment_id);
CREATE INDEX wcti ON worker_charges(task_id);

COMMIT;
