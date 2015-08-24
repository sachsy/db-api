--------------------------------------
--------------------------- FUNCTIONS:
--------------------------------------

-- PARAMS: tasks.id
CREATE FUNCTION seconds_per_task(integer, OUT seconds integer) AS $$
BEGIN
	seconds := (EXTRACT(EPOCH FROM finished_at) - EXTRACT(EPOCH FROM started_at))
		FROM muckwork.tasks WHERE id = $1;
END;
$$ LANGUAGE plpgsql;
-- FYI: SELECT SUM(seconds_per_task(id)) FROM muckwork.tasks WHERE project_id=1;

-- TODO:
--  SELECT currency, (millicents_per_second * seconds_per_task(1)) FROM workers WHERE workers.id = 1;


-- next tasks.sortid for project
-- tasks.sortid resort
