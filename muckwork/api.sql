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


