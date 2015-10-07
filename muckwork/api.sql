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
	IF cid IS NULL THEN m4_NOTFOUND
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
	IF wid IS NULL THEN m4_NOTFOUND
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
	IF mid IS NULL THEN m4_NOTFOUND
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
EXCEPTION WHEN OTHERS THEN  -- if illegal status text passed into params
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
EXCEPTION WHEN OTHERS THEN  -- if illegal status text passed into params
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
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: person_id
CREATE OR REPLACE FUNCTION create_client(integer,
	OUT mime text, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.clients(person_id) VALUES ($1) RETURNING id INTO new_id;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_client(new_id) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id, JSON of key=>values to update
CREATE OR REPLACE FUNCTION update_client(integer, json,
	OUT mime text, OUT js json) AS $$
DECLARE
	pid integer;
m4_ERRVARS
BEGIN
	SELECT person_id INTO pid FROM muckwork.clients WHERE id = $1;
	PERFORM peeps.jsonupdate('peeps.people', pid, $2,
		ARRAY['name', 'email', 'address', 'company', 'city', 'state', 'country', 'phone']);
	PERFORM peeps.jsonupdate('muckwork.clients', $1, $2,
		ARRAY['person_id', 'currency']);
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_client($1) x;
m4_ERRCATCH
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
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: person_id
CREATE OR REPLACE FUNCTION create_worker(integer,
	OUT mime text, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.workers(person_id) VALUES ($1) RETURNING id INTO new_id;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_worker(new_id) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: worker_id, JSON of key=>values to update
CREATE OR REPLACE FUNCTION update_worker(integer, json,
	OUT mime text, OUT js json) AS $$
DECLARE
	pid integer;
m4_ERRVARS
BEGIN
	SELECT person_id INTO pid FROM muckwork.workers WHERE id = $1;
	PERFORM peeps.jsonupdate('peeps.people', pid, $2,
		ARRAY['name', 'email', 'address', 'company', 'city', 'state', 'country', 'phone']);
	PERFORM peeps.jsonupdate('muckwork.workers', $1, $2,
		ARRAY['person_id', 'currency', 'millicents_per_second']);
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_worker($1) x;
m4_ERRCATCH
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
EXCEPTION WHEN OTHERS THEN  -- if illegal status text passed into params
	js := '[]';
END;
$$ LANGUAGE plpgsql;


-- PARAMS: project_id
CREATE OR REPLACE FUNCTION get_project(integer,
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := row_to_json(r) FROM (SELECT * FROM muckwork.project_detail_view WHERE id = $1) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id, title, description
CREATE OR REPLACE FUNCTION create_project(integer, text, text,
	OUT mime text, OUT js json) AS $$
DECLARE
m4_ERRVARS
	new_id integer;
BEGIN
	INSERT INTO muckwork.projects (client_id, title, description)
		VALUES ($1, $2, $3) RETURNING id INTO new_id;
	mime := 'application/json';
	js := row_to_json(r) FROM (SELECT * FROM muckwork.project_view WHERE id = new_id) r;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, title, description
CREATE OR REPLACE FUNCTION update_project(integer, text, text,
	OUT mime text, OUT js json) AS $$
BEGIN
	UPDATE muckwork.projects SET title = $2, description = $3 WHERE id = $1;
	mime := 'application/json';
	js := row_to_json(r) FROM (SELECT * FROM muckwork.project_view WHERE id = $1) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
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
m4_NOTFOUND
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
	IF js IS NULL THEN m4_NOTFOUND END IF;
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
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, title, description, sortid(or NULL)
CREATE OR REPLACE FUNCTION create_task(integer, text, text, integer,
	OUT mime text, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.tasks(project_id, title, description, sortid)
		VALUES ($1, $2, $3, $4) RETURNING id INTO new_id;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task(new_id) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id, title, description, sortid(or NULL)
CREATE OR REPLACE FUNCTION update_task(integer, text, text, integer,
	OUT mime text, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks SET title = $2, description = $3, sortid = $4
		WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id, worker_id
CREATE OR REPLACE FUNCTION claim_task(integer, integer,
	OUT mime text, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks SET worker_id = $2, claimed_at = NOW() WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION unclaim_task(integer,
	OUT mime text, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks SET worker_id = NULL, claimed_at = NULL WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION start_task(integer,
	OUT mime text, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks SET started_at = NOW() WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION finish_task(integer,
	OUT mime text, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks SET finished_at = NOW() WHERE id = $1;
	SELECT x.mime, x.js INTO mime, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
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



-- lists just the next unclaimed task (lowest sortid) for each project
-- use this to avoid workers claiming tasks out of order
-- PARAMS: -none-
CREATE OR REPLACE FUNCTION next_available_tasks(
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := json_agg(r) FROM (SELECT * FROM muckwork.task_view
		WHERE (project_id, sortid) IN (SELECT project_id, MIN(sortid)
			FROM muckwork.tasks WHERE status='approved'
			AND worker_id IS NULL AND claimed_at IS NULL
			GROUP BY project_id) 
		ORDER BY project_id) r;
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
EXCEPTION WHEN OTHERS THEN  -- if illegal status text passed into params
	js := '[]';
END;
$$ LANGUAGE plpgsql;



--  check finality of project
--  email customer
