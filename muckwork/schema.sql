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
	project_id integer REFERENCES projects(id) ON DELETE CASCADE,
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


-- can't update existing timestamps
-- not sure what's better: one trigger for all dates, or one trigger per field.
CREATE FUNCTION dates_cant_change_pc() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.created_at IS NOT NULL AND OLD.created_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER dates_cant_change_pc BEFORE UPDATE OF created_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pc();

CREATE FUNCTION dates_cant_change_pq() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.quoted_at IS NOT NULL AND OLD.quoted_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER dates_cant_change_pq BEFORE UPDATE OF quoted_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pq();

CREATE FUNCTION dates_cant_change_pa() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.approved_at IS NOT NULL AND OLD.approved_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER dates_cant_change_pa BEFORE UPDATE OF approved_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pa();

CREATE FUNCTION dates_cant_change_ps() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.started_at IS NOT NULL AND OLD.started_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER dates_cant_change_ps BEFORE UPDATE OF started_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_ps();

CREATE FUNCTION dates_cant_change_pf() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.finished_at IS NOT NULL AND OLD.finished_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER dates_cant_change_pf BEFORE UPDATE OF finished_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pf();

CREATE FUNCTION dates_cant_change_tc() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.created_at IS NOT NULL AND OLD.created_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER dates_cant_change_tc BEFORE UPDATE OF created_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_tc();

CREATE FUNCTION dates_cant_change_tl() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.claimed_at IS NOT NULL AND OLD.claimed_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER dates_cant_change_tl BEFORE UPDATE OF claimed_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_tl();

CREATE FUNCTION dates_cant_change_ts() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.started_at IS NOT NULL AND OLD.started_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER dates_cant_change_ts BEFORE UPDATE OF started_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_ts();

CREATE FUNCTION dates_cant_change_tf() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.finished_at IS NOT NULL AND OLD.finished_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER dates_cant_change_tf BEFORE UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_tf();



CREATE FUNCTION task_status() RETURNS TRIGGER AS $$
BEGIN
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


-- can't delete started projects or tasks
CREATE FUNCTION no_delete_started() RETURNS TRIGGER AS $$
BEGIN
	IF OLD.started_at IS NOT NULL 
		THEN RAISE 'no_delete_started';
	END IF;
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER no_delete_started_project BEFORE DELETE ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_delete_started();
CREATE TRIGGER no_delete_started_task BEFORE DELETE ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_delete_started();


-- can't update title, description of quoted project
CREATE FUNCTION no_update_quoted_project() RETURNS TRIGGER AS $$
BEGIN
	IF OLD.quoted_at IS NOT NULL 
		THEN RAISE 'no_update_quoted';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER no_update_quoted_project BEFORE UPDATE OF
	title, description ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_update_quoted_project();


-- can't update title, description of started task
CREATE FUNCTION no_update_started_task() RETURNS TRIGGER AS $$
BEGIN
	IF OLD.started_at IS NOT NULL 
		THEN RAISE 'no_update_started';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER no_update_started_task BEFORE UPDATE OF
	title, description ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_update_started_task();


-- first task started marks project as started (see reverse below)
CREATE FUNCTION task_starts_project() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.projects SET started_at=NOW()
		WHERE id=OLD.project_id AND started_at IS NULL;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER task_starts_project AFTER UPDATE OF started_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.started_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.task_starts_project();

-- only started task un-started marks project as un-started
CREATE FUNCTION task_unstarts_project() RETURNS TRIGGER AS $$
DECLARE
	pi integer;
BEGIN
	SELECT project_id INTO pi FROM muckwork.tasks
		WHERE project_id=OLD.project_id
		AND started_at IS NOT NULL LIMIT 1;
	IF pi IS NULL THEN
		UPDATE muckwork.projects SET started_at=NULL WHERE id=OLD.project_id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER task_unstarts_project AFTER UPDATE OF started_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.started_at IS NULL)
	EXECUTE PROCEDURE muckwork.task_unstarts_project();


-- last task finished marks project as finished (see reverse below)
CREATE FUNCTION task_finishes_project() RETURNS TRIGGER AS $$
DECLARE
	pi integer;
BEGIN
	-- any unfinished tasks left for this project?
	SELECT project_id INTO pi FROM muckwork.tasks
		WHERE project_id=OLD.project_id
		AND finished_at IS NULL LIMIT 1;
	-- ... if not, then mark project as finished_at time of last finished_at task
	IF pi IS NULL THEN
		UPDATE muckwork.projects SET finished_at =
			(SELECT MAX(finished_at) FROM tasks WHERE project_id=OLD.project_id)
			WHERE id=OLD.project_id AND finished_at IS NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER task_finishes_project AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.task_finishes_project();

-- last finished task un-finished marks project as un-finished again
CREATE FUNCTION task_unfinishes_project() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.projects SET finished_at=NULL
		WHERE id=OLD.project_id AND finished_at IS NOT NULL;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER task_unfinishes_project AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NULL)
	EXECUTE PROCEDURE muckwork.task_unfinishes_project();


-- task finished creates worker_charge  (see reverse below)
CREATE FUNCTION task_creates_charge() RETURNS TRIGGER AS $$
BEGIN
	WITH x AS (
		SELECT NEW.id AS task_id, currency, cents
		FROM muckwork.worker_charge_for_task(NEW.id))
	INSERT INTO muckwork.worker_charges (task_id, currency, cents) SELECT * FROM x;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER task_creates_charge AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.task_creates_charge();

-- task UN-finished deletes associated charge
CREATE FUNCTION task_uncreates_charge() RETURNS TRIGGER AS $$
BEGIN
	DELETE FROM muckwork.worker_charges WHERE task_id = NEW.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER task_uncreates_charge AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NULL)
	EXECUTE PROCEDURE muckwork.task_uncreates_charge();

-- approving project makes tasks approved
CREATE FUNCTION approve_project_tasks() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.tasks SET status='approved'
		WHERE project_id=OLD.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER approve_project_tasks AFTER UPDATE OF approved_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.approved_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.approve_project_tasks();

-- UN-approving project makes tasks UN-approved 
CREATE FUNCTION unapprove_project_tasks() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.tasks SET status='quoted'
		WHERE project_id=OLD.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER unapprove_project_tasks AFTER UPDATE OF approved_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.approved_at IS NULL)
	EXECUTE PROCEDURE muckwork.unapprove_project_tasks();


-- project finished creates charge
-- TODO: fixed vs hourly (& hey maybe I should profit?)
CREATE FUNCTION project_creates_charge() RETURNS TRIGGER AS $$
DECLARE
	nu_currency char(3);
	nu_cents integer;
BEGIN
	SELECT * INTO nu_currency, nu_cents
		FROM muckwork.final_project_charges(NEW.id);
	UPDATE muckwork.projects
		SET final_currency = nu_currency, final_cents = nu_cents
		WHERE id = NEW.id;
	INSERT INTO muckwork.charges (project_id, currency, cents)
		VALUES (NEW.id, nu_currency, nu_cents);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER project_creates_charge AFTER UPDATE OF finished_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.finished_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.project_creates_charge();


--------------------------------------
--------------------------- FUNCTIONS:
--------------------------------------

-- PARAMS: tasks.id
-- USAGE: SELECT SUM(seconds_per_task(id)) FROM muckwork.tasks WHERE project_id=1;
CREATE FUNCTION seconds_per_task(integer, OUT seconds integer) AS $$
BEGIN
	seconds := (EXTRACT(EPOCH FROM finished_at) - EXTRACT(EPOCH FROM started_at))
		FROM muckwork.tasks
		WHERE id = $1
		AND finished_at IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- PARAMS: tasks.id
-- NOTE: to convert millicents into cents, rounds UP to the next highest cent
CREATE FUNCTION worker_charge_for_task(integer, OUT currency char(3), OUT cents integer) AS $$
BEGIN
	SELECT w.currency,
		CEIL((w.millicents_per_second * muckwork.seconds_per_task(t.id)) / 100)
		INTO currency, cents
		FROM muckwork.tasks t
		LEFT JOIN muckwork.workers w ON t.worker_id=w.id
		WHERE t.id = $1
		AND t.finished_at IS NOT NULL;
END;
$$ LANGUAGE plpgsql;


-- Sum of all worker_charges for tasks in this project, *converted* to project currency
CREATE FUNCTION final_project_charges(integer, OUT currency char(3), OUT cents integer) AS $$
DECLARE
	project_currency char(3);
	wc muckwork.worker_charges;
	sum_cents numeric := 0;
BEGIN
	-- figure out what currency to quote in
	SELECT final_currency INTO project_currency FROM muckwork.projects WHERE id = $1;
	IF project_currency IS NULL THEN
		SELECT muckwork.clients.currency INTO project_currency FROM muckwork.clients
			JOIN muckwork.projects ON muckwork.clients.id=muckwork.projects.client_id
			WHERE muckwork.projects.id = $1;
	END IF;
	-- go through charges for this project:
	FOR wc IN SELECT * FROM muckwork.worker_charges
		JOIN muckwork.tasks ON muckwork.worker_charges.task_id=muckwork.tasks.id
		WHERE muckwork.tasks.project_id = $1 LOOP
		SELECT sum_cents + amount INTO sum_cents
			FROM peeps.currency_from_to(wc.cents, wc.currency, project_currency);
	END LOOP;
	currency := project_currency;
	-- round up to cent integer
	cents := CEIL(sum_cents);
END;
$$ LANGUAGE plpgsql;



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
	-- SELECT c.*, p.name, p.email FROM muckwork.clients c, peeps.people p WHERE c.person_id=p.id ORDER BY id DESC
	js := '[]';
END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id
CREATE OR REPLACE FUNCTION get_client(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	-- SELECT c.*, p.name, p.email FROM muckwork.clients c, peeps.people p WHERE c.person_id=p.id AND c.id=$1
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



