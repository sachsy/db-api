----------------------------------------
--------------- VIEWS FOR JSON RESPONSES:
----------------------------------------

DROP VIEW IF EXISTS project_view CASCADE;
CREATE VIEW project_view AS SELECT id, title, description, created_at,
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

DROP VIEW IF EXISTS task_view CASCADE;
CREATE VIEW task_view AS SELECT t.*,
	(SELECT row_to_json(px) AS project FROM
		(SELECT id, title, description
			FROM muckwork.projects
			WHERE projects.id=t.project_id) px),
	(SELECT row_to_json(wx) AS worker FROM
		(SELECT w.*, p.name, p.email
			FROM muckwork.workers w, peeps.people p
			WHERE w.person_id=p.id AND w.id=t.worker_id) wx)
	FROM muckwork.tasks t
	ORDER BY t.sortid ASC;

DROP VIEW IF EXISTS project_detail_view CASCADE;
CREATE VIEW project_detail_view AS SELECT id, title, description, created_at,
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
			ORDER BY t.sortid ASC) tx)
	FROM muckwork.projects j;

