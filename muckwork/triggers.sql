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
-- SOME DAY: fixed vs hourly (& hey maybe I should profit?)
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


-- project UN-finished UN-creates charge
CREATE FUNCTION project_uncreates_charge() RETURNS TRIGGER AS $$
BEGIN
	UPDATE muckwork.projects
		SET final_currency = NULL, final_cents = NULL
		WHERE id = NEW.id;
	DELETE FROM muckwork.charges WHERE project_id = NEW.id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER project_uncreates_charge AFTER UPDATE OF finished_at ON muckwork.projects
	FOR EACH ROW WHEN (NEW.finished_at IS NULL)
	EXECUTE PROCEDURE muckwork.project_uncreates_charge();


