----------------------------------------
--------------- VIEWS FOR JSON RESPONSES:
----------------------------------------

DROP VIEW IF EXISTS peeps.people_view CASCADE;
CREATE VIEW peeps.people_view AS
	SELECT id, name, email, email_count FROM peeps.people;

DROP VIEW IF EXISTS peeps.person_view CASCADE;
CREATE VIEW peeps.person_view AS
	SELECT id, name, address, email, company, city, state, country, notes, phone, 
		listype, categorize_as, created_at,
		(SELECT json_agg(s) AS stats FROM
			(SELECT id, created_at, statkey AS name, statvalue AS value
				FROM peeps.userstats WHERE person_id=peeps.people.id ORDER BY id) s),
		(SELECT json_agg(u) AS urls FROM
			(SELECT id, url, main FROM peeps.urls WHERE person_id=peeps.people.id
				ORDER BY main DESC NULLS LAST, id) u),
		(SELECT json_agg(e) AS emails FROM
			(SELECT id, created_at, subject, outgoing FROM peeps.emails
				WHERE person_id=peeps.people.id ORDER BY id) e)
		FROM peeps.people;

DROP VIEW IF EXISTS peeps.emails_view CASCADE;
CREATE VIEW peeps.emails_view AS
	SELECT id, subject, created_at, their_name, their_email FROM peeps.emails;

DROP VIEW IF EXISTS peeps.emails_full_view CASCADE;
CREATE VIEW peeps.emails_full_view AS
	SELECT id, message_id, profile, category, created_at, opened_at, closed_at,
		their_email, their_name, subject, headers, body, outgoing, person_id
		FROM peeps.emails;

DROP VIEW IF EXISTS peeps.email_view CASCADE;
CREATE VIEW peeps.email_view AS
	SELECT id, profile, category,
		created_at, (SELECT row_to_json(p1) AS creator FROM
			(SELECT emailers.id, people.name FROM peeps.emailers
				JOIN people ON emailers.person_id=people.id
				WHERE peeps.emailers.id = created_by) p1),
		opened_at, (SELECT row_to_json(p2) AS openor FROM
			(SELECT emailers.id, people.name FROM peeps.emailers
				JOIN people ON emailers.person_id=people.id
				WHERE peeps.emailers.id = opened_by) p2),
		closed_at, (SELECT row_to_json(p3) AS closor FROM
			(SELECT emailers.id, people.name FROM peeps.emailers
				JOIN people ON emailers.person_id=people.id
				WHERE peeps.emailers.id = closed_by) p3),
		message_id, outgoing, reference_id, answer_id,
		their_email, their_name, headers, subject, body,
		(SELECT json_agg(a) AS attachments FROM
			(SELECT id, filename FROM peeps.email_attachments WHERE email_id=peeps.emails.id) a),
		(SELECT row_to_json(p) AS person FROM
			(SELECT * FROM peeps.person_view WHERE id = person_id) p)
		FROM peeps.emails;

DROP VIEW IF EXISTS peeps.unknown_view CASCADE;
CREATE VIEW peeps.unknown_view AS
	SELECT id, their_email, their_name, headers, subject, body FROM peeps.emails;

DROP VIEW IF EXISTS peeps.formletters_view CASCADE;
CREATE VIEW peeps.formletters_view AS
	SELECT id, title, explanation, created_at FROM peeps.formletters;

DROP VIEW IF EXISTS peeps.formletter_view CASCADE;
CREATE VIEW peeps.formletter_view AS
	SELECT id, title, explanation, body, created_at FROM peeps.formletters;

DROP VIEW IF EXISTS peeps.stats_view CASCADE;
CREATE VIEW peeps.stats_view AS
	SELECT userstats.id, userstats.created_at, statkey AS name, statvalue AS value,
		(SELECT row_to_json(p) FROM
			(SELECT people.id, people.name, people.email) p) AS person
		FROM peeps.userstats INNER JOIN people ON userstats.person_id=people.id
		ORDER BY userstats.id DESC;

