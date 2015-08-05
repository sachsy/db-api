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
----------------------------
------------------ TRIGGERS:
----------------------------

-- TODO: can't delete started projects or tasks
-- TODO: can't update description of started project or task
-- TODO: can't update existing timestamps

CREATE FUNCTION project_status() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.quoted_at IS NULL THEN
		NEW.status := 'created';
	ELSIF NEW.approved_at IS NULL THEN
		NEW.status := 'quoted';
	ELSIF NEW.started_at IS NULL THEN
		NEW.status := 'approved';
	ELSIF NEW.finished_at IS NULL THEN
		NEW.status := 'started';
	ELSE
		NEW.status := 'finished';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER project_status BEFORE UPDATE OF
	quoted_at, approved_at, started_at, finished_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.project_status();


-- Dates must always exist in this order:
-- created_at, quoted_at, approved_at, started_at, finished_at
CREATE FUNCTION project_dates_in_order() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.approved_at IS NOT NULL AND NEW.quoted_at IS NULL)
		OR (NEW.started_at IS NOT NULL AND NEW.approved_at IS NULL)
		OR (NEW.finished_at IS NOT NULL AND NEW.started_at IS NULL)
		THEN RAISE 'dates_out_of_order';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER project_dates_in_order BEFORE UPDATE OF
	quoted_at, approved_at, started_at, finished_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.project_dates_in_order();


CREATE FUNCTION task_status() RETURNS TRIGGER AS $$
BEGIN
	-- TODO: approved?
	IF NEW.started_at IS NULL THEN
		NEW.status := 'created';
	ELSIF NEW.finished_at IS NULL THEN
		NEW.status := 'started';
	ELSE
		NEW.status := 'finished';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER task_status BEFORE UPDATE OF
	started_at, finished_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.task_status();


-- Dates must always exist in this order:
-- created_at, started_at, finished_at
CREATE FUNCTION task_dates_in_order() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.finished_at IS NOT NULL AND NEW.started_at IS NULL)
		OR (NEW.started_at IS NOT NULL AND NEW.claimed_at IS NULL)
		THEN RAISE 'dates_out_of_order';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER task_dates_in_order BEFORE UPDATE OF
	claimed_at, started_at, finished_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.task_dates_in_order();


CREATE FUNCTION no_cents_without_currency() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.quoted_cents IS NOT NULL AND NEW.quoted_currency IS NULL)
	OR (NEW.final_cents IS NOT NULL AND NEW.final_currency IS NULL)
		THEN RAISE 'no_cents_without_currency';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER no_cents_without_currency BEFORE UPDATE OF
	quoted_cents, final_cents ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_cents_without_currency();


-- tasks.claimed_at and tasks.worker_id must match (both|neither)
CREATE FUNCTION tasks_claimed_pair() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.claimed_at IS NOT NULL AND NEW.worker_id IS NULL)
	OR (NEW.worker_id IS NOT NULL AND NEW.claimed_at IS NULL)
		THEN RAISE 'tasks_claimed_pair';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER tasks_claimed_pair BEFORE UPDATE OF
	worker_id, claimed_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.tasks_claimed_pair();


--------------------------------------
--------------------------- FUNCTIONS:
--------------------------------------

-- TODO: create worker_charge from task:
-- seconds per task (id)
-- seconds per project (id)

-- check finality of project
-- each task finished?
-- update project finished_at

-- next tasks.sortid for project
-- tasks.sortid resort
----------------------------------------
--------------- VIEWS FOR JSON RESPONSES:
----------------------------------------

----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

-- PARAMS: (none)
CREATE OR REPLACE FUNCTION get_clients(
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '[]';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id
CREATE OR REPLACE FUNCTION get_client(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: person_id
CREATE OR REPLACE FUNCTION create_client(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id, currency
CREATE OR REPLACE FUNCTION update_client(integer, text,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: (none)
CREATE OR REPLACE FUNCTION get_workers(
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '[]';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: worker_id
CREATE OR REPLACE FUNCTION get_worker(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: person_id
CREATE OR REPLACE FUNCTION create_worker(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: worker_id, currency, millicents_per_second
CREATE OR REPLACE FUNCTION update_worker(integer, text, integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS:  (none)
CREATE OR REPLACE FUNCTION get_projects(
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '[]';
END;
$$ LANGUAGE plpgsql;



-- PARAMS:  status
CREATE OR REPLACE FUNCTION get_projects_with_status(text,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '[]';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id
CREATE OR REPLACE FUNCTION get_project(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id, title, description
CREATE OR REPLACE FUNCTION create_project(integer, text, text,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, title, description
CREATE OR REPLACE FUNCTION update_project(integer, text, text,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, ratetype, currency, cents
CREATE OR REPLACE FUNCTION quote_project(integer, text, text, integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	-- set final_currency same as quoted_currency
	-- set quoted_at
	-- set tasks to quoted
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id
CREATE OR REPLACE FUNCTION approve_quote(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	-- set tasks to approved
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, description
-- TODO: instead of update description, add notes
CREATE OR REPLACE FUNCTION refuse_quote(integer, text,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, title, description, sortid(or NULL)
CREATE OR REPLACE FUNCTION create_task(integer, text, text, integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	-- get next sortid for project
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id, title, description, sortid(or NULL)
CREATE OR REPLACE FUNCTION update_task(integer, text, text, integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id, worker_id
CREATE OR REPLACE FUNCTION claim_task(integer, integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION unclaim_task(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION start_task(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	-- TODO: if first task in project, mark project started
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION finish_task(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	-- TODO: if last task in project, mark project finished
	mime := 'application/json';
	js := '{}';
END;
$$ LANGUAGE plpgsql;



-- TODO: complete_task
--	set finished_at time to now
--	create worker_charge for task
--  check finality of project
--  email customer



