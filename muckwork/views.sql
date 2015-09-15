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

