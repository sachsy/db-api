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
	currency char(3) REFERENCES peeps.currencies(code),
	cents_balance integer not null default 0
);

CREATE TABLE workers (
	id serial primary key,
	person_id integer not null unique REFERENCES peeps.people(id),
	rating integer not null default 50,
	currency char(3) REFERENCES peeps.currencies(code),
	millicents_per_second integer
);

CREATE TABLE projects (
	id serial primary key,
	client_id integer not null REFERENCES clients(id),
	title text,
	description text,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	quoted_at timestamp(0) with time zone,
	approved_at timestamp(0) with time zone,
	started_at timestamp(0) with time zone,
	finished_at timestamp(0) with time zone,
	seconds integer,
	quoted_currency char(3) REFERENCES peeps.currencies(code),
	quoted_cents integer,
	quoted_ratetype varchar(4), -- time, fix
	final_currency char(3) REFERENCES peeps.currencies(code),
	final_cents integer
);
CREATE INDEX pjci ON projects(client_id);
CREATE INDEX pjsa ON projects(started_at);
CREATE INDEX pjaa ON projects(finished_at);
	
CREATE TABLE tasks (
	id serial primary key,
	project_id integer REFERENCES projects(id),
	worker_id integer REFERENCES workers(id),
	sortid integer,
	title text,
	description text,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	started_at timestamp(0) with time zone,
	finished_at timestamp(0) with time zone
);
CREATE INDEX tpi ON tasks(project_id);
CREATE INDEX twi ON tasks(worker_id);
CREATE INDEX tsa ON tasks(started_at);
CREATE INDEX tfa ON tasks(finished_at);

CREATE TABLE charges (
	id serial primary key,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	project_id integer REFERENCES projects(id),
	currency char(3) not null REFERENCES peeps.currencies(code),
	cents integer not null,
	notes text
);
CREATE INDEX chpi ON charges(project_id);

CREATE TABLE payments (
	id serial primary key,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	client_id integer REFERENCES clients(id),
	currency char(3) not null REFERENCES peeps.currencies(code),
	cents integer not null,
	notes text
);
CREATE INDEX pci ON payments(client_id);

CREATE TABLE worker_payments (
	id serial primary key,
	worker_id integer not null REFERENCES workers(id),
	currency char(3) not null REFERENCES peeps.currencies(code),
	cents integer,
	created_at date not null default CURRENT_DATE,
	notes text
);
CREATE INDEX wpwi ON worker_payments(worker_id);

CREATE TABLE worker_charges (
	id serial primary key,
	task_id integer not null REFERENCES tasks(id),
	currency char(3) not null REFERENCES peeps.currencies(code),
	cents integer not null,
	payment_id integer REFERENCES worker_payments(id) -- NULL until paid
);
CREATE INDEX wcpi ON worker_charges(payment_id);
CREATE INDEX wcti ON worker_charges(task_id);

COMMIT;
