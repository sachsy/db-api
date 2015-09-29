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

