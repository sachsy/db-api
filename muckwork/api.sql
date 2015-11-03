----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

-- PARAMS: api_key, api_pass
-- RESPONSE: {client_id: (integer)} or not found
CREATE OR REPLACE FUNCTION muckwork.auth_client(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	cid integer;
	pid integer;
BEGIN
	SELECT c.id, c.person_id INTO cid, pid
		FROM peeps.api_keys a, muckwork.clients c
		WHERE a.akey=$1 AND a.apass=$2 AND 'MuckworkClient'=ANY(a.apis)
		AND a.person_id=c.person_id;
	IF cid IS NULL THEN m4_NOTFOUND
	ELSE
		status := 200;
		js := json_build_object('client_id', cid, 'person_id', pid);
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: api_key, api_pass
-- RESPONSE: {worker_id: (integer)} or not found
CREATE OR REPLACE FUNCTION muckwork.auth_worker(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	wid integer;
	pid integer;
BEGIN
	SELECT w.id, w.person_id INTO wid, pid
		FROM peeps.api_keys a, muckwork.workers w
		WHERE a.akey=$1 AND a.apass=$2 AND 'Muckworker'=ANY(a.apis)
		AND a.person_id=w.person_id;
	IF wid IS NULL THEN m4_NOTFOUND
	ELSE
		status := 200;
		js := json_build_object('worker_id', wid, 'person_id', pid);
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: api_key, api_pass
-- RESPONSE: {manager_id: (integer)} or not found
CREATE OR REPLACE FUNCTION muckwork.auth_manager(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	mid integer;
	pid integer;
BEGIN
	SELECT m.id, m.person_id INTO mid, pid
		FROM peeps.api_keys a, muckwork.managers m
		WHERE a.akey=$1 AND a.apass=$2 AND 'MuckworkManager'=ANY(a.apis)
		AND a.person_id=m.person_id;
	IF mid IS NULL THEN m4_NOTFOUND
	ELSE
		status := 200;
		js := json_build_object('manager_id', mid, 'person_id', pid);
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: client_id, project_id
-- RESPONSE: {'ok' = boolean}  (so 'ok' = 'false' means no)
CREATE OR REPLACE FUNCTION muckwork.client_owns_project(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
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
CREATE OR REPLACE FUNCTION muckwork.worker_owns_task(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	PERFORM 1 FROM muckwork.tasks WHERE worker_id = $1 AND id = $2;
	IF FOUND IS TRUE THEN
		js := '{"ok": true}';
	ELSE
		js := '{"ok": false}';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: project_id, progress
-- RESPONSE: {'ok' = boolean}  (so 'ok' = 'false' means no)
CREATE OR REPLACE FUNCTION muckwork.project_has_progress(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	PERFORM 1 FROM muckwork.projects WHERE id = $1 AND progress = $2::progress;
	IF FOUND IS TRUE THEN
		js := '{"ok": true}';
	ELSE
		js := '{"ok": false}';
	END IF;
EXCEPTION WHEN OTHERS THEN  -- if illegal progress text passed into params
	js := '{"ok": false}';
END;
$$ LANGUAGE plpgsql;


-- PARAMS: task_id, progress
-- RESPONSE: {'ok' = boolean}  (so 'ok' = 'false' means no)
CREATE OR REPLACE FUNCTION muckwork.task_has_progress(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	PERFORM 1 FROM muckwork.tasks WHERE id = $1 AND progress = $2::progress;
	IF FOUND IS TRUE THEN
		js := '{"ok": true}';
	ELSE
		js := '{"ok": false}';
	END IF;
EXCEPTION WHEN OTHERS THEN  -- if illegal progress text passed into params
	js := '{"ok": false}';
END;
$$ LANGUAGE plpgsql;


-- PARAMS: (none)
CREATE OR REPLACE FUNCTION muckwork.get_clients(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT c.*, p.name, p.email
		FROM muckwork.clients c, peeps.people p
		WHERE c.person_id=p.id ORDER BY id DESC) r;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id
CREATE OR REPLACE FUNCTION muckwork.get_client(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (SELECT c.*, p.name, p.email,
		p.address, p.company, p.city, p.state, p.country, p.phone
		FROM muckwork.clients c, peeps.people p
		WHERE c.person_id=p.id AND c.id=$1) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: person_id
CREATE OR REPLACE FUNCTION muckwork.create_client(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.clients(person_id) VALUES ($1) RETURNING id INTO new_id;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_client(new_id) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id, JSON of key=>values to update
CREATE OR REPLACE FUNCTION muckwork.update_client(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
m4_ERRVARS
BEGIN
	SELECT person_id INTO pid FROM muckwork.clients WHERE id = $1;
	PERFORM core.jsonupdate('peeps.people', pid, $2,
		ARRAY['name', 'email', 'address', 'company', 'city', 'state', 'country', 'phone']);
	PERFORM core.jsonupdate('muckwork.clients', $1, $2,
		ARRAY['person_id', 'currency']);
	SELECT x.status, x.js INTO status, js FROM muckwork.get_client($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: (none)
CREATE OR REPLACE FUNCTION muckwork.get_workers(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT w.*, p.name, p.email
		FROM muckwork.workers w, peeps.people p
		WHERE w.person_id=p.id ORDER BY id DESC) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: worker_id
CREATE OR REPLACE FUNCTION muckwork.get_worker(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (SELECT w.*, p.name, p.email,
		p.address, p.company, p.city, p.state, p.country, p.phone
		FROM muckwork.workers w, peeps.people p
		WHERE w.person_id=p.id AND w.id=$1) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: person_id
CREATE OR REPLACE FUNCTION muckwork.create_worker(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.workers(person_id) VALUES ($1) RETURNING id INTO new_id;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_worker(new_id) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: worker_id, JSON of key=>values to update
CREATE OR REPLACE FUNCTION muckwork.update_worker(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
m4_ERRVARS
BEGIN
	SELECT person_id INTO pid FROM muckwork.workers WHERE id = $1;
	PERFORM core.jsonupdate('peeps.people', pid, $2,
		ARRAY['name', 'email', 'address', 'company', 'city', 'state', 'country', 'phone']);
	PERFORM core.jsonupdate('muckwork.workers', $1, $2,
		ARRAY['person_id', 'currency', 'millicents_per_second']);
	SELECT x.status, x.js INTO status, js FROM muckwork.get_worker($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS:  (none)
CREATE OR REPLACE FUNCTION muckwork.get_projects(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM muckwork.project_view) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS:  client_id
CREATE OR REPLACE FUNCTION muckwork.client_get_projects(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM muckwork.project_view WHERE id IN
		(SELECT id FROM muckwork.projects WHERE client_id = $1)) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: progress ('created','quoted','approved','refused','started','finished')
CREATE OR REPLACE FUNCTION muckwork.get_projects_with_progress(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM muckwork.project_view WHERE progress = $1::progress) r;
	IF js IS NULL THEN js := '[]'; END IF;
EXCEPTION WHEN OTHERS THEN  -- if illegal progress text passed into params
	js := '[]';
END;
$$ LANGUAGE plpgsql;


-- PARAMS: project_id
CREATE OR REPLACE FUNCTION muckwork.get_project(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM muckwork.project_detail_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: client_id, title, description
CREATE OR REPLACE FUNCTION muckwork.create_project(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
	new_id integer;
BEGIN
	INSERT INTO muckwork.projects (client_id, title, description)
		VALUES ($1, $2, $3) RETURNING id INTO new_id;
	status := 200;
	js := row_to_json(r.*) FROM muckwork.project_view r WHERE id = new_id;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, title, description
CREATE OR REPLACE FUNCTION muckwork.update_project(integer, text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE muckwork.projects SET title = $2, description = $3 WHERE id = $1;
	status := 200;
	js := row_to_json(r.*) FROM muckwork.project_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, ratetype, currency, cents
CREATE OR REPLACE FUNCTION muckwork.quote_project(integer, text, text, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE muckwork.projects SET quoted_at = NOW(), quoted_ratetype = $2,
		quoted_currency = $3, final_currency = $3, quoted_cents = $4
		WHERE id = $1;
	UPDATE muckwork.tasks SET progress = 'quoted' WHERE project_id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_project($1) x;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id
CREATE OR REPLACE FUNCTION muckwork.approve_quote(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE muckwork.projects SET approved_at = NOW() WHERE id = $1;
	UPDATE muckwork.tasks SET progress = 'approved' WHERE project_id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_project($1) x;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, explanation
CREATE OR REPLACE FUNCTION muckwork.refuse_quote(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	note_id integer;
BEGIN
	UPDATE muckwork.projects SET progress = 'refused' WHERE id = $1 AND progress = 'quoted';
	IF FOUND IS FALSE THEN
m4_NOTFOUND
	ELSE
		INSERT INTO muckwork.notes (project_id, client_id, note)
			VALUES ($1, (SELECT client_id FROM projects WHERE id = $1), $2)
			RETURNING id INTO note_id;
		status := 200;
		js := row_to_json(r.*) FROM muckwork.notes r WHERE id = note_id;
	END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION muckwork.get_task(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM muckwork.task_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, task.id
-- (Same as get_task but including project_id for ownership verification.)
CREATE OR REPLACE FUNCTION muckwork.get_project_task(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM muckwork.task_view r
		WHERE project_id = $1 AND id = $2;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: project_id, title, description, sortid(or NULL)
CREATE OR REPLACE FUNCTION muckwork.create_task(integer, text, text, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO muckwork.tasks(project_id, title, description, sortid)
		VALUES ($1, $2, $3, $4) RETURNING id INTO new_id;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task(new_id) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id, title, description, sortid(or NULL)
CREATE OR REPLACE FUNCTION muckwork.update_task(integer, text, text, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks SET title = $2, description = $3, sortid = $4
		WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id, worker_id
CREATE OR REPLACE FUNCTION muckwork.claim_task(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks SET worker_id = $2, claimed_at = NOW() WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION muckwork.unclaim_task(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks SET worker_id = NULL, claimed_at = NULL WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION muckwork.start_task(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks SET started_at = NOW() WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS: task.id
CREATE OR REPLACE FUNCTION muckwork.finish_task(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE muckwork.tasks SET finished_at = NOW() WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM muckwork.get_task($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;



-- PARAMS:  worker_id
CREATE OR REPLACE FUNCTION muckwork.worker_get_tasks(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM muckwork.task_view WHERE id IN
		(SELECT id FROM muckwork.tasks WHERE worker_id = $1)
		ORDER BY id DESC) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- lists just the next unclaimed task (lowest sortid) for each project
-- use this to avoid workers claiming tasks out of order
-- PARAMS: -none-
CREATE OR REPLACE FUNCTION muckwork.next_available_tasks(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM muckwork.task_view
		WHERE (project_id, sortid) IN (SELECT project_id, MIN(sortid)
			FROM muckwork.tasks WHERE progress='approved'
			AND worker_id IS NULL AND claimed_at IS NULL
			GROUP BY project_id) 
		ORDER BY project_id) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: progress ('created','quoted','approved','refused','started','finished')
CREATE OR REPLACE FUNCTION muckwork.get_tasks_with_progress(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM muckwork.task_view WHERE progress = $1::progress) r;
	IF js IS NULL THEN js := '[]'; END IF;
EXCEPTION WHEN OTHERS THEN  -- if illegal progress text passed into params
	js := '[]';
END;
$$ LANGUAGE plpgsql;



--  check finality of project
--  email customer
