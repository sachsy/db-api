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
CREATE FUNCTION worker_cost_for_task(integer, OUT currency char(3), OUT millicents integer) AS $$
BEGIN
	SELECT w.currency,
		(w.millicents_per_second * muckwork.seconds_per_task(t.id))
		INTO currency, millicents
		FROM muckwork.tasks t
		LEFT JOIN muckwork.workers w ON t.worker_id=w.id
		WHERE t.id = $1
		AND t.finished_at IS NOT NULL;
END;
$$ LANGUAGE plpgsql;


-- next tasks.sortid for project
-- tasks.sortid resort
