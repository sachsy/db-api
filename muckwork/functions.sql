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

-- next tasks.sortid for project
-- tasks.sortid resort
