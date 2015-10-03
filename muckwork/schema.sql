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

CREATE TABLE notes (
	id serial primary key,
	created_at timestamp(0) with time zone not null default CURRENT_TIMESTAMP,
	project_id integer REFERENCES projects(id),
	task_id integer REFERENCES tasks(id),
	manager_id integer REFERENCES managers(id),
	client_id integer REFERENCES clients(id),
	worker_id integer REFERENCES workers(id),
	note text not null CONSTRAINT note_not_empty CHECK (length(note) > 0)
);
CREATE INDEX notpi ON notes(project_id);
CREATE INDEX notti ON notes(task_id);

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

CREATE OR REPLACE FUNCTION project_status() RETURNS TRIGGER AS $$
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
DROP TRIGGER IF EXISTS project_status ON muckwork.projects CASCADE;
CREATE TRIGGER project_status BEFORE UPDATE OF
	quoted_at, approved_at, started_at, finished_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.project_status();


-- Dates must always exist in this order:
-- created_at, quoted_at, approved_at, started_at, finished_at
CREATE OR REPLACE FUNCTION project_dates_in_order() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.approved_at IS NOT NULL AND NEW.quoted_at IS NULL)
		OR (NEW.started_at IS NOT NULL AND NEW.approved_at IS NULL)
		OR (NEW.finished_at IS NOT NULL AND NEW.started_at IS NULL)
		THEN RAISE 'dates_out_of_order';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS project_dates_in_order ON muckwork.projects CASCADE;
CREATE TRIGGER project_dates_in_order BEFORE UPDATE OF
	quoted_at, approved_at, started_at, finished_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.project_dates_in_order();


-- can't update existing timestamps
-- not sure what's better: one trigger for all dates, or one trigger per field.
CREATE OR REPLACE FUNCTION dates_cant_change_pc() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.created_at IS NOT NULL AND OLD.created_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_pc ON muckwork.projects CASCADE;
CREATE TRIGGER dates_cant_change_pc BEFORE UPDATE OF created_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pc();

CREATE OR REPLACE FUNCTION dates_cant_change_pq() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.quoted_at IS NOT NULL AND OLD.quoted_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_pq ON muckwork.projects CASCADE;
CREATE TRIGGER dates_cant_change_pq BEFORE UPDATE OF quoted_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pq();

CREATE OR REPLACE FUNCTION dates_cant_change_pa() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.approved_at IS NOT NULL AND OLD.approved_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_pa ON muckwork.projects CASCADE;
CREATE TRIGGER dates_cant_change_pa BEFORE UPDATE OF approved_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pa();

CREATE OR REPLACE FUNCTION dates_cant_change_ps() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.started_at IS NOT NULL AND OLD.started_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_ps ON muckwork.projects CASCADE;
CREATE TRIGGER dates_cant_change_ps BEFORE UPDATE OF started_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_ps();

CREATE OR REPLACE FUNCTION dates_cant_change_pf() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.finished_at IS NOT NULL AND OLD.finished_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_pf ON muckwork.projects CASCADE;
CREATE TRIGGER dates_cant_change_pf BEFORE UPDATE OF finished_at ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_pf();

CREATE OR REPLACE FUNCTION dates_cant_change_tc() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.created_at IS NOT NULL AND OLD.created_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_tc ON muckwork.tasks CASCADE;
CREATE TRIGGER dates_cant_change_tc BEFORE UPDATE OF created_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_tc();

CREATE OR REPLACE FUNCTION dates_cant_change_tl() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.claimed_at IS NOT NULL AND OLD.claimed_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_tl ON muckwork.tasks CASCADE;
CREATE TRIGGER dates_cant_change_tl BEFORE UPDATE OF claimed_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_tl();

CREATE OR REPLACE FUNCTION dates_cant_change_ts() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.started_at IS NOT NULL AND OLD.started_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_ts ON muckwork.tasks CASCADE;
CREATE TRIGGER dates_cant_change_ts BEFORE UPDATE OF started_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_ts();

CREATE OR REPLACE FUNCTION dates_cant_change_tf() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.finished_at IS NOT NULL AND OLD.finished_at IS NOT NULL)
		THEN RAISE 'dates_cant_change';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS dates_cant_change_tf ON muckwork.tasks CASCADE;
CREATE TRIGGER dates_cant_change_tf BEFORE UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.dates_cant_change_tf();



CREATE OR REPLACE FUNCTION task_status() RETURNS TRIGGER AS $$
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
DROP TRIGGER IF EXISTS task_status ON muckwork.tasks CASCADE;
CREATE TRIGGER task_status BEFORE UPDATE OF
	started_at, finished_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.task_status();


-- Dates must always exist in this order:
-- created_at, started_at, finished_at
CREATE OR REPLACE FUNCTION task_dates_in_order() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.finished_at IS NOT NULL AND NEW.started_at IS NULL)
		OR (NEW.started_at IS NOT NULL AND NEW.claimed_at IS NULL)
		THEN RAISE 'dates_out_of_order';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_dates_in_order ON muckwork.tasks CASCADE;
CREATE TRIGGER task_dates_in_order BEFORE UPDATE OF
	claimed_at, started_at, finished_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.task_dates_in_order();


CREATE OR REPLACE FUNCTION no_cents_without_currency() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.quoted_cents IS NOT NULL AND NEW.quoted_currency IS NULL)
	OR (NEW.final_cents IS NOT NULL AND NEW.final_currency IS NULL)
		THEN RAISE 'no_cents_without_currency';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS no_cents_without_currency ON muckwork.projects CASCADE;
CREATE TRIGGER no_cents_without_currency BEFORE UPDATE OF
	quoted_cents, final_cents ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_cents_without_currency();


-- tasks.claimed_at and tasks.worker_id must match (both|neither)
CREATE OR REPLACE FUNCTION tasks_claimed_pair() RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.claimed_at IS NOT NULL AND NEW.worker_id IS NULL)
	OR (NEW.worker_id IS NOT NULL AND NEW.claimed_at IS NULL)
		THEN RAISE 'tasks_claimed_pair';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS tasks_claimed_pair ON muckwork.tasks CASCADE;
CREATE TRIGGER tasks_claimed_pair BEFORE UPDATE OF
	worker_id, claimed_at ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.tasks_claimed_pair();


-- can't delete started projects or tasks
CREATE OR REPLACE FUNCTION no_delete_started() RETURNS TRIGGER AS $$
BEGIN
	IF OLD.started_at IS NOT NULL 
		THEN RAISE 'no_delete_started';
	END IF;
	RETURN OLD;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS no_delete_started_project ON muckwork.projects CASCADE;
CREATE TRIGGER no_delete_started_project BEFORE DELETE ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_delete_started();
DROP TRIGGER IF EXISTS no_delete_started_task ON muckwork.tasks CASCADE;
CREATE TRIGGER no_delete_started_task BEFORE DELETE ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_delete_started();


-- can't update title, description of quoted project
CREATE OR REPLACE FUNCTION no_update_quoted_project() RETURNS TRIGGER AS $$
BEGIN
	IF OLD.quoted_at IS NOT NULL 
		THEN RAISE 'no_update_quoted';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS no_update_quoted_project ON muckwork.projects CASCADE;
CREATE TRIGGER no_update_quoted_project BEFORE UPDATE OF
	title, description ON muckwork.projects
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_update_quoted_project();


-- can't update title, description of started task
CREATE OR REPLACE FUNCTION no_update_started_task() RETURNS TRIGGER AS $$
BEGIN
	IF OLD.started_at IS NOT NULL 
		THEN RAISE 'no_update_started';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS no_update_started_task ON muckwork.tasks CASCADE;
CREATE TRIGGER no_update_started_task BEFORE UPDATE OF
	title, description ON muckwork.tasks
	FOR EACH ROW EXECUTE PROCEDURE muckwork.no_update_started_task();


-- first task started marks project as started (see reverse below)
CREATE OR REPLACE FUNCTION task_starts_project() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.projects SET started_at=NOW()
		WHERE id=OLD.project_id AND started_at IS NULL;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_starts_project ON muckwork.tasks CASCADE;
CREATE TRIGGER task_starts_project AFTER UPDATE OF started_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.started_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.task_starts_project();

-- only started task un-started marks project as un-started
CREATE OR REPLACE FUNCTION task_unstarts_project() RETURNS TRIGGER AS $$
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
DROP TRIGGER IF EXISTS task_unstarts_project ON muckwork.tasks CASCADE;
CREATE TRIGGER task_unstarts_project AFTER UPDATE OF started_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.started_at IS NULL)
	EXECUTE PROCEDURE muckwork.task_unstarts_project();


-- last task finished marks project as finished (see reverse below)
CREATE OR REPLACE FUNCTION task_finishes_project() RETURNS TRIGGER AS $$
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
DROP TRIGGER IF EXISTS task_finishes_project ON muckwork.tasks CASCADE;
CREATE TRIGGER task_finishes_project AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.task_finishes_project();

-- last finished task un-finished marks project as un-finished again
CREATE OR REPLACE FUNCTION task_unfinishes_project() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.projects SET finished_at=NULL
		WHERE id=OLD.project_id AND finished_at IS NOT NULL;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_unfinishes_project ON muckwork.tasks CASCADE;
CREATE TRIGGER task_unfinishes_project AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NULL)
	EXECUTE PROCEDURE muckwork.task_unfinishes_project();


-- task finished creates worker_charge  (see reverse below)
CREATE OR REPLACE FUNCTION task_creates_charge() RETURNS TRIGGER AS $$
BEGIN
	WITH x AS (
		SELECT NEW.id AS task_id, currency, cents
		FROM muckwork.worker_charge_for_task(NEW.id))
	INSERT INTO muckwork.worker_charges (task_id, currency, cents) SELECT * FROM x;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_creates_charge ON muckwork.tasks CASCADE;
CREATE TRIGGER task_creates_charge AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.task_creates_charge();

-- task UN-finished deletes associated charge
CREATE OR REPLACE FUNCTION task_uncreates_charge() RETURNS TRIGGER AS $$
BEGIN
	DELETE FROM muckwork.worker_charges WHERE task_id = NEW.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS task_uncreates_charge ON muckwork.tasks CASCADE;
CREATE TRIGGER task_uncreates_charge AFTER UPDATE OF finished_at ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.finished_at IS NULL)
	EXECUTE PROCEDURE muckwork.task_uncreates_charge();

-- approving project makes tasks approved
CREATE OR REPLACE FUNCTION approve_project_tasks() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.tasks SET status='approved'
		WHERE project_id=OLD.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS approve_project_tasks ON muckwork.projects CASCADE;
CREATE TRIGGER approve_project_tasks AFTER UPDATE OF approved_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.approved_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.approve_project_tasks();

-- UN-approving project makes tasks UN-approved 
CREATE OR REPLACE FUNCTION unapprove_project_tasks() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.tasks SET status='quoted'
		WHERE project_id=OLD.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS unapprove_project_tasks ON muckwork.projects CASCADE;
CREATE TRIGGER unapprove_project_tasks AFTER UPDATE OF approved_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.approved_at IS NULL)
	EXECUTE PROCEDURE muckwork.unapprove_project_tasks();


-- project finished creates charge
-- SOME DAY: fixed vs hourly (& hey maybe I should profit?)
CREATE OR REPLACE FUNCTION project_creates_charge() RETURNS TRIGGER AS $$
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
DROP TRIGGER IF EXISTS project_creates_charge ON muckwork.projects CASCADE;
CREATE TRIGGER project_creates_charge AFTER UPDATE OF finished_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.finished_at IS NOT NULL)
	EXECUTE PROCEDURE muckwork.project_creates_charge();


-- project UN-finished UN-creates charge
CREATE OR REPLACE FUNCTION project_uncreates_charge() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.projects
		SET final_currency = NULL, final_cents = NULL
		WHERE id = NEW.id;
	DELETE FROM muckwork.charges WHERE project_id = NEW.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS project_uncreates_charge ON muckwork.projects CASCADE;
CREATE TRIGGER project_uncreates_charge AFTER UPDATE OF finished_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.finished_at IS NULL)
	EXECUTE PROCEDURE muckwork.project_uncreates_charge();


-- template
CREATE OR REPLACE FUNCTION auto_sortid() RETURNS TRIGGER AS $$
DECLARE
	i integer;
BEGIN
	SELECT COALESCE(MAX(sortid), 0) INTO i
		FROM muckwork.tasks WHERE project_id=NEW.project_id;
	NEW.sortid = (i + 1);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS auto_sortid ON muckwork.tasks CASCADE;
CREATE TRIGGER auto_sortid BEFORE INSERT ON muckwork.tasks
	FOR EACH ROW WHEN (NEW.sortid IS NULL)
	EXECUTE PROCEDURE muckwork.auto_sortid();


-- template
-- CREATE OR REPLACE FUNCTION xx() RETURNS TRIGGER AS $$
-- BEGIN
-- 	RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
-- DROP TRIGGER IF EXISTS xx ON muckwork.projects CASCADE;
-- CREATE TRIGGER xx AFTER UPDATE OF yy ON muckwork.projects
-- 	FOR EACH ROW WHEN (NEW.yy IS NULL)
-- 	EXECUTE PROCEDURE muckwork.xx();

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
		INNER JOIN muckwork.workers w ON t.worker_id=w.id
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

DROP VIEW IF EXISTS muckwork.project_view CASCADE;
CREATE VIEW muckwork.project_view AS SELECT id, title, description, created_at,
	quoted_at, approved_at, started_at, finished_at, status,
	(SELECT row_to_json(cx) AS client FROM
		(SELECT c.*, p.name, p.email
			FROM muckwork.clients c, peeps.people p
			WHERE c.person_id=p.id AND c.id=client_id) cx),
	quoted_ratetype,
	json_build_object('currency', quoted_currency, 'cents', quoted_cents) quoted_money,
	json_build_object('currency', final_currency, 'cents', final_cents) final_money
	FROM muckwork.projects
	ORDER BY muckwork.projects.id DESC;

DROP VIEW IF EXISTS muckwork.task_view CASCADE;
CREATE VIEW muckwork.task_view AS SELECT t.*,
	(SELECT row_to_json(px) AS project FROM
		(SELECT id, title, description
			FROM muckwork.projects
			WHERE muckwork.projects.id=t.project_id) px),
	(SELECT row_to_json(wx) AS worker FROM
		(SELECT w.*, p.name, p.email
			FROM muckwork.workers w, peeps.people p
			WHERE w.person_id=p.id AND w.id=t.worker_id) wx),
	(SELECT json_agg(nx) AS notes FROM
		(SELECT id, created_at, manager_id, client_id, worker_id, note
			FROM muckwork.notes n
			WHERE n.task_id = t.id
			ORDER BY n.id ASC) nx)
	FROM muckwork.tasks t
	ORDER BY t.sortid ASC;

DROP VIEW IF EXISTS muckwork.project_detail_view CASCADE;
CREATE VIEW muckwork.project_detail_view AS SELECT id, title, description, created_at,
	quoted_at, approved_at, started_at, finished_at, status,
	(SELECT row_to_json(cx) AS client FROM
		(SELECT c.*, p.name, p.email
			FROM muckwork.clients c, peeps.people p
			WHERE c.person_id=p.id AND c.id=client_id) cx),
	quoted_ratetype,
	json_build_object('currency', quoted_currency, 'cents', quoted_cents) quoted_money,
	json_build_object('currency', final_currency, 'cents', final_cents) final_money,
	(SELECT json_agg(tx) AS tasks FROM
		(SELECT t.*,
			(SELECT row_to_json(wx) AS worker FROM
				(SELECT w.*, p.name, p.email
					FROM muckwork.workers w, peeps.people p
					WHERE w.person_id=p.id AND w.id=t.worker_id) wx)
			FROM muckwork.tasks t
			WHERE t.project_id = j.id
			ORDER BY t.sortid ASC) tx),
	(SELECT json_agg(nx) AS notes FROM
		(SELECT id, created_at, task_id, manager_id, client_id, worker_id, note
			FROM muckwork.notes n
			WHERE n.project_id = j.id
			ORDER BY n.id ASC) nx)
	FROM muckwork.projects j;

----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

-- PARAMS: api_key, api_pass
-- RESPONSE: {client_id: (integer)} or not found
CREATE OR REPLACE FUNCTION auth_client(text, text,
	OUT mime text, OUT js json) AS $$
DECLARE
	cid integer;
BEGIN
	SELECT c.id INTO cid
		FROM peeps.api_keys a, muckwork.clients c
		WHERE a.akey=$1 AND a.apass=$2 AND 'MuckworkClient'=ANY(a.apis)
		AND a.person_id=c.person_id;
	IF cid IS NULL THEN 
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'about:blank',
		'title', 'Not Found',
		'status', 404);

	ELSE
		mime := 'application/json';
		js := json_build_object('client_id', cid);
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: api_key, api_pass
-- RESPONSE: {worker_id: (integer)} or not found
CREATE OR REPLACE FUNCTION auth_worker(text, text,
	OUT mime text, OUT js json) AS $$
DECLARE
	wid integer;
BEGIN
	SELECT w.id INTO wid
		FROM peeps.api_keys a, muckwork.workers w
		WHERE a.akey=$1 AND a.apass=$2 AND 'Muckworker'=ANY(a.apis)
		AND a.person_id=w.person_id;
	IF wid IS NULL THEN 
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'about:blank',
		'title', 'Not Found',
		'status', 404);

	ELSE
		mime := 'application/json';
		js := json_build_object('worker_id', wid);
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: api_key, api_pass
-- RESPONSE: {manager_id: (integer)} or not found
CREATE OR REPLACE FUNCTION auth_manager(text, text,
	OUT mime text, OUT js json) AS $$
DECLARE
	mid integer;
BEGIN
	SELECT m.id INTO mid
		FROM peeps.api_keys a, muckwork.managers m
		WHERE a.akey=$1 AND a.apass=$2 AND 'MuckworkManager'=ANY(a.apis)
		AND a.person_id=m.person_id;
	IF mid IS NULL THEN 
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'about:blank',
		'title', 'Not Found',
		'status', 404);

	ELSE
		mime := 'application/json';
		js := json_build_object('manager_id', mid);
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: client_id, project_id
-- RESPONSE: {'ok' = boolean}  (so 'ok' = 'false' means no)
CREATE OR REPLACE FUNCTION client_owns_project(integer, integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	PERFORM 1 FROM muckwork.projects WHERE client_id = $1 AND id = $2;
	IF FOUND IS TRUE THEN
		js := '{"ok": true}';
	ELSE
		js := '{"ok": false}';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: worker_id, task_id
-- RESPONSE: {'ok' = boolean}  (so 'ok' = 'false' means no)
CREATE OR REPLACE FUNCTION worker_owns_task(integer, integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	PERFORM 1 FROM muckwork.tasks WHERE worker_id = $1 AND id = $2;
	IF FOUND IS TRUE THEN
		js := '{"ok": true}';
	ELSE
		js := '{"ok": false}';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: project_id, status
-- RESPONSE: {'ok' = boolean}  (so 'ok' = 'false' means no)
CREATE OR REPLACE FUNCTION project_has_status(integer, text,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	PERFORM 1 FROM muckwork.projects WHERE id = $1 AND status = $2::status;
	IF FOUND IS TRUE THEN
		js := '{"ok": true}';
	ELSE
		js := '{"ok": false}';
	END IF;
EXCEPTION WHEN OTHERS THEN
	js := '{"ok": false}';
END;
$$ LANGUAGE plpgsql;


-- PARAMS: task_id, status
-- RESPONSE: {'ok' = boolean}  (so 'ok' = 'false' means no)
CREATE OR REPLACE FUNCTION task_has_status(integer, text,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	PERFORM 1 FROM muckwork.tasks WHERE id = $1 AND status = $2::status;
	IF FOUND IS TRUE THEN
		js := '{"ok": true}';
	ELSE
		js := '{"ok": false}';
	END IF;
EXCEPTION WHEN OTHERS THEN
	js := '{"ok": false}';
END;
$$ LANGUAGE plpgsql;


-- PARAMS: (none)
CREATE OR REPLACE FUNCTION get_clients(
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := json_agg(r) FROM (SELECT c.*, p.name, p.email
		FROM muckwork.clients c, peeps.people p
		WHERE c.person_id=p.id ORDER BY id DESC) r;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id
CREATE OR REPLACE FUNCTION get_client(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := row_to_json(r) FROM (SELECT c.*, p.name, p.email,
		p.address, p.company, p.city, p.state, p.country, p.phone
		FROM muckwork.clients c, peeps.people p
		WHERE c.person_id=p.id AND c.id=$1) r;
	IF js IS NULL THEN 
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'about:blank',
		'title', 'Not Found',
		'status', 404);
 END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: person_id
CREATE OR REPLACE FUNCTION create_client(integer,
	OUT mime text, OUT js json) AS $$
DECLARE
	new_id integer;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	INSERT INTO muckwork.clients(person_id) VALUES ($1) RETURNING id INTO new_id;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_client(new_id) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id, currency
CREATE OR REPLACE FUNCTION update_client(integer, text,
	OUT mime text, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.clients SET currency=$2 WHERE id=$1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_client($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;



-- PARAMS: (none)
CREATE OR REPLACE FUNCTION get_workers(
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := json_agg(r) FROM (SELECT w.*, p.name, p.email
		FROM muckwork.workers w, peeps.people p
		WHERE w.person_id=p.id ORDER BY id DESC) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: worker_id
CREATE OR REPLACE FUNCTION get_worker(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := row_to_json(r) FROM (SELECT w.*, p.name, p.email,
		p.address, p.company, p.city, p.state, p.country, p.phone
		FROM muckwork.workers w, peeps.people p
		WHERE w.person_id=p.id AND w.id=$1) r;
	IF js IS NULL THEN 
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'about:blank',
		'title', 'Not Found',
		'status', 404);
 END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: person_id
CREATE OR REPLACE FUNCTION create_worker(integer,
	OUT mime text, OUT js json) AS $$
DECLARE
	new_id integer;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	INSERT INTO muckwork.workers(person_id) VALUES ($1) RETURNING id INTO new_id;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_worker(new_id) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;



-- PARAMS: worker_id, currency, millicents_per_second
CREATE OR REPLACE FUNCTION update_worker(integer, text, integer,
	OUT mime text, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.workers SET currency=$2, millicents_per_second=$3 WHERE id=$1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_worker($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;



-- PARAMS:  (none)
CREATE OR REPLACE FUNCTION get_projects(
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := json_agg(r) FROM (SELECT * FROM muckwork.project_view) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS:  client_id
CREATE OR REPLACE FUNCTION client_get_projects(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := json_agg(r) FROM (SELECT * FROM muckwork.project_view WHERE id IN
		(SELECT id FROM muckwork.projects WHERE client_id = $1)) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: status ('created','quoted','approved','refused','started','finished')
CREATE OR REPLACE FUNCTION get_projects_with_status(text,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := json_agg(r) FROM (SELECT * FROM muckwork.project_view WHERE status = $1::status) r;
	IF js IS NULL THEN js := '[]'; END IF;
EXCEPTION WHEN OTHERS THEN
	js := '[]';
END;
$$ LANGUAGE plpgsql;


-- PARAMS: project_id
CREATE OR REPLACE FUNCTION get_project(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := row_to_json(r) FROM (SELECT * FROM muckwork.project_detail_view WHERE id = $1) r;
	IF js IS NULL THEN 
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'about:blank',
		'title', 'Not Found',
		'status', 404);
 END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id, title, description
CREATE OR REPLACE FUNCTION create_project(integer, text, text,
	OUT mime text, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

	new_id integer;
BEGIN
	INSERT INTO muckwork.projects (client_id, title, description)
		VALUES ($1, $2, $3) RETURNING id INTO new_id;
	mime := 'application/json';
	js := row_to_json(r) FROM (SELECT * FROM muckwork.project_view WHERE id = new_id) r;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, title, description
CREATE OR REPLACE FUNCTION update_project(integer, text, text,
	OUT mime text, OUT js json) AS $$
BEGIN
	UPDATE muckwork.projects SET title = $2, description = $3 WHERE id = $1;
	mime := 'application/json';
	js := row_to_json(r) FROM (SELECT * FROM muckwork.project_view WHERE id = $1) r;
	IF js IS NULL THEN 
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'about:blank',
		'title', 'Not Found',
		'status', 404);
 END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, ratetype, currency, cents
CREATE OR REPLACE FUNCTION quote_project(integer, text, text, integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	UPDATE muckwork.projects SET quoted_at = NOW(), quoted_ratetype = $2,
		quoted_currency = $3, final_currency = $3, quoted_cents = $4
		WHERE id = $1;
	UPDATE muckwork.tasks SET status = 'quoted' WHERE project_id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_project($1) x;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id
CREATE OR REPLACE FUNCTION approve_quote(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	UPDATE muckwork.projects SET approved_at = NOW() WHERE id = $1;
	UPDATE muckwork.tasks SET status = 'approved' WHERE project_id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_project($1) x;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, explanation
CREATE OR REPLACE FUNCTION refuse_quote(integer, text,
	OUT mime text, OUT js json) AS $$
DECLARE
	note_id integer;
BEGIN
	UPDATE muckwork.projects SET status = 'refused' WHERE id = $1 AND status = 'quoted';
	IF FOUND IS FALSE THEN

	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'about:blank',
		'title', 'Not Found',
		'status', 404);

	ELSE
		INSERT INTO muckwork.notes (project_id, client_id, note)
			VALUES ($1, (SELECT client_id FROM projects WHERE id = $1), $2)
			RETURNING id INTO note_id;
		mime := 'application/json';
		js := row_to_json(r) FROM (SELECT * FROM muckwork.notes WHERE id = note_id) r;
	END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION get_task(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := row_to_json(r) FROM
		(SELECT * FROM muckwork.task_view WHERE id = $1) r;
	IF js IS NULL THEN 
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'about:blank',
		'title', 'Not Found',
		'status', 404);
 END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, task.id
-- (Same as get_task but including project_id for ownership verification.)
CREATE OR REPLACE FUNCTION get_project_task(integer, integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := row_to_json(r) FROM
		(SELECT * FROM muckwork.task_view WHERE project_id = $1 AND id = $2) r;
	IF js IS NULL THEN 
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'about:blank',
		'title', 'Not Found',
		'status', 404);
 END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, title, description, sortid(or NULL)
CREATE OR REPLACE FUNCTION create_task(integer, text, text, integer,
	OUT mime text, OUT js json) AS $$
DECLARE
	new_id integer;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	INSERT INTO muckwork.tasks(project_id, title, description, sortid)
		VALUES ($1, $2, $3, $4) RETURNING id INTO new_id;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task(new_id) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id, title, description, sortid(or NULL)
CREATE OR REPLACE FUNCTION update_task(integer, text, text, integer,
	OUT mime text, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.tasks SET title = $2, description = $3, sortid = $4
		WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id, worker_id
CREATE OR REPLACE FUNCTION claim_task(integer, integer,
	OUT mime text, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.tasks SET worker_id = $2, claimed_at = NOW() WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION unclaim_task(integer,
	OUT mime text, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.tasks SET worker_id = NULL, claimed_at = NULL WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION start_task(integer,
	OUT mime text, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.tasks SET started_at = NOW() WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION finish_task(integer,
	OUT mime text, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE muckwork.tasks SET finished_at = NOW() WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task($1) x;

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	mime := 'application/problem+json';
	js := json_build_object(
		'type', 'http://www.postgresql.org/docs/9.4/static/errcodes-appendix.html#' || err_code,
		'title', err_msg,
		'detail', err_detail || err_context);

END;
$$ LANGUAGE plpgsql;



-- PARAMS:  worker_id
CREATE OR REPLACE FUNCTION worker_get_tasks(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := json_agg(r) FROM (SELECT * FROM muckwork.task_view WHERE id IN
		(SELECT id FROM muckwork.tasks WHERE worker_id = $1)
		ORDER BY id DESC) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: status ('created','quoted','approved','refused','started','finished')
CREATE OR REPLACE FUNCTION get_tasks_with_status(text,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := json_agg(r) FROM (SELECT * FROM muckwork.task_view WHERE status = $1::status) r;
	IF js IS NULL THEN js := '[]'; END IF;
EXCEPTION WHEN OTHERS THEN
	js := '[]';
END;
$$ LANGUAGE plpgsql;



--  check finality of project
--  email customer

