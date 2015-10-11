--------------------------------------
--------------------------- FUNCTIONS:
--------------------------------------

-- PARAMS: tasks.id
-- USAGE: SELECT SUM(seconds_per_task(id)) FROM muckwork.tasks WHERE project_id=1;
CREATE OR REPLACE FUNCTION seconds_per_task(integer, OUT seconds integer) AS $$
BEGIN
	seconds := (EXTRACT(EPOCH FROM finished_at) - EXTRACT(EPOCH FROM started_at))
		FROM muckwork.tasks
		WHERE id = $1
		AND finished_at IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- PARAMS: tasks.id
-- NOTE: to convert millicents into cents, rounds UP to the next highest cent
CREATE OR REPLACE FUNCTION worker_charge_for_task(integer, OUT currency char(3), OUT cents integer) AS $$
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
CREATE OR REPLACE FUNCTION final_project_charges(integer, OUT currency char(3), OUT cents integer) AS $$
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
			FROM core.currency_from_to(wc.cents, wc.currency, project_currency);
	END LOOP;
	currency := project_currency;
	-- round up to cent integer
	cents := CEIL(sum_cents);
END;
$$ LANGUAGE plpgsql;


-- Is this worker available to claim another task?
-- Current rule: not if they have another task claimed and unfinished
-- Rule might change, so that's why making it a separate function.
-- INPUT: worker_id
CREATE OR REPLACE FUNCTION is_worker_available(integer) RETURNS boolean AS $$
BEGIN
	RETURN NOT EXISTS (SELECT 1 FROM muckwork.tasks
		WHERE worker_id=$1 AND finished_at IS NULL);
END;
$$ LANGUAGE plpgsql;


-- next tasks.sortid for project
-- tasks.sortid resort
