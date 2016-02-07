----------------------------------------
------------------------- API FUNCTIONS:
----------------------------------------

-- API REQUIRES AUTHENTICATION. User must be in peeps.emailers
-- peeps.emailers.id needed as first argument to many functions here

-- PARAMS: person_id, API_name
CREATE OR REPLACE FUNCTION peeps.add_api(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
m4_ERRVARS
BEGIN
	SELECT person_id INTO pid FROM peeps.api_keys WHERE person_id = $1;
	IF pid IS NULL THEN
		INSERT INTO peeps.api_keys(person_id) VALUES ($1);
	END IF;
	status := 200;
	WITH nu AS (UPDATE peeps.api_keys
		SET apis = array_append(array_remove(apis, $2), $2)
		WHERE person_id=$1 RETURNING *)
		SELECT row_to_json(nu.*) INTO js FROM nu;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: email, password, API_name
CREATE OR REPLACE FUNCTION peeps.auth_api(text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.api_keys r
		WHERE person_id = (SELECT id FROM peeps.person_email_pass($1, $2))
		AND $3 = ANY(apis);
	IF js IS NULL THEN m4_NOTFOUND END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: akey, apass
CREATE OR REPLACE FUNCTION peeps.auth_emailer(text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (SELECT e.id 
		FROM peeps.api_keys a, peeps.emailers e
		WHERE a.akey=$1 AND a.apass=$2 AND 'Peep'=ANY(a.apis)
		AND a.person_id = e.person_id) r;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /emails/unopened/count
-- Grouped summary of howmany unopened emails in each profile/category
-- JSON format: {profiles:{categories:howmany}}
--{"derek@sivers":{"derek@sivers":43,"derek":2,"programmer":1},
-- "we@woodegg":{"woodeggRESEARCH":1,"woodegg":1,"we@woodegg":1}}
-- PARAMS: emailer_id
CREATE OR REPLACE FUNCTION peeps.unopened_email_count(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_object_agg(profile, cats) FROM (WITH unopened AS
		(SELECT profile, category FROM peeps.emails WHERE id IN
			(SELECT * FROM peeps.unopened_email_ids($1)))
		SELECT profile, (SELECT json_object_agg(category, num) FROM
			(SELECT category, COUNT(*) AS num FROM unopened u2
				WHERE u2.profile=unopened.profile
				GROUP BY category ORDER BY num DESC) rr)
		AS cats FROM unopened GROUP BY profile) r;  
	IF js IS NULL THEN
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /emails/unopened/:profile/:category
-- PARAMS: emailer_id, profile, category
CREATE OR REPLACE FUNCTION peeps.unopened_emails(integer, text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.emails_view WHERE id IN
		(SELECT id FROM peeps.emails WHERE id IN (SELECT * FROM peeps.unopened_email_ids($1))
			AND profile = $2 AND category = $3) ORDER BY id) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- POST /emails/next/:profile/:category
-- Opens email (updates status as opened by this emailer) then returns view
-- PARAMS: emailer_id, profile, category
CREATE OR REPLACE FUNCTION peeps.open_next_email(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	eid integer;
BEGIN
	SELECT id INTO eid FROM peeps.emails
		WHERE id IN (SELECT * FROM peeps.unopened_email_ids($1))
		AND profile=$2 AND category=$3 ORDER BY id LIMIT 1;
	IF eid IS NULL THEN
m4_NOTFOUND
	ELSE
		status := 200;
		PERFORM open_email($1, eid);
		js := row_to_json(r.*) FROM peeps.email_view r WHERE id = eid;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /emails/opened
-- PARAMS: emailer_id
CREATE OR REPLACE FUNCTION peeps.opened_emails(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT e.id, subject, opened_at, p.name
		FROM peeps.emails e
		JOIN peeps.emailers r ON e.opened_by=r.id
		JOIN peeps.people p ON r.person_id=p.id
		WHERE e.id IN 
			(SELECT * FROM peeps.opened_email_ids($1)) ORDER BY opened_at) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /emails/:id
-- PARAMS: emailer_id, email_id
CREATE OR REPLACE FUNCTION peeps.get_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	eid integer;
BEGIN
	eid := open_email($1, $2);
	IF eid IS NULL THEN
m4_NOTFOUND
	ELSE
		status := 200;
		js := row_to_json(r.*) FROM peeps.email_view r WHERE id = eid;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PUT /emails/:id
-- PARAMS: emailer_id, email_id, JSON of new values
CREATE OR REPLACE FUNCTION peeps.update_email(integer, integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	eid integer;
m4_ERRVARS
BEGIN
	eid := peeps.ok_email($1, $2);
	IF eid IS NULL THEN
m4_NOTFOUND
	ELSE
		PERFORM core.jsonupdate('peeps.emails', eid, $3,
			core.cols2update('peeps', 'emails', ARRAY['id', 'created_at']));
		status := 200;
		js := row_to_json(r.*) FROM peeps.email_view r WHERE id = eid;
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- DELETE /emails/:id
-- PARAMS: emailer_id, email_id
CREATE OR REPLACE FUNCTION peeps.delete_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	eid integer;
BEGIN
	eid := peeps.ok_email($1, $2);
	IF eid IS NULL THEN
m4_NOTFOUND
	ELSE
		status := 200;
		js := row_to_json(r.*) FROM peeps.email_view r WHERE id = eid;
		DELETE FROM peeps.emails WHERE id = eid;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PUT /emails/:id/close
-- PARAMS: emailer_id, email_id
CREATE OR REPLACE FUNCTION peeps.close_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	eid integer;
BEGIN
	eid := peeps.ok_email($1, $2);
	IF eid IS NULL THEN
m4_NOTFOUND
	ELSE
		UPDATE peeps.emails SET closed_at=NOW(), closed_by=$1 WHERE id = eid;
		status := 200;
		js := row_to_json(r.*) FROM peeps.email_view r WHERE id = eid;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PUT /emails/:id/unread
-- PARAMS: emailer_id, email_id
CREATE OR REPLACE FUNCTION peeps.unread_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	eid integer;
BEGIN
	eid := peeps.ok_email($1, $2);
	IF eid IS NULL THEN
m4_NOTFOUND
	ELSE
		UPDATE peeps.emails SET opened_at=NULL, opened_by=NULL,
			closed_at=NULL, closed_by=NULL WHERE id = eid;
		status := 200;
		js := row_to_json(r.*) FROM peeps.email_view r WHERE id = eid;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PUT /emails/:id/notme
-- PARAMS: emailer_id, email_id
CREATE OR REPLACE FUNCTION peeps.not_my_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	eid integer;
BEGIN
	eid := peeps.ok_email($1, $2);
	IF eid IS NULL THEN
m4_NOTFOUND
	ELSE
		UPDATE peeps.emails SET opened_at=NULL, opened_by=NULL,
			closed_at=NULL, closed_by=NULL, category=(SELECT
			substring(concat('not-', split_part(people.email,'@',1)) from 1 for 8)
			FROM peeps.emailers JOIN people ON emailers.person_id=people.id
			WHERE emailers.id = $1) WHERE id = eid;
		status := 200;
		js := row_to_json(r.*) FROM peeps.email_view r WHERE id = eid;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- POST /emails/:id/reply?body=blah
-- PARAMS: emailer_id, email_id, body
CREATE OR REPLACE FUNCTION peeps.reply_to_email(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	eid integer;
	e emails;
	new_id integer;
m4_ERRVARS
BEGIN
	IF $3 IS NULL OR (regexp_replace($3, '\s', '', 'g') = '') THEN
		RAISE 'body must not be empty';
	END IF;
	eid := peeps.ok_email($1, $2);
	IF eid IS NULL THEN
m4_NOTFOUND
	ELSE
		SELECT * INTO e FROM peeps.emails WHERE id = eid;
		IF e IS NULL THEN
m4_NOTFOUND
		ELSE
			-- PARAMS: emailer_id, person_id, profile, category, subject, body, reference_id 
			SELECT * INTO new_id FROM peeps.outgoing_email($1, e.person_id, e.profile, e.profile,
				concat('re: ', regexp_replace(e.subject, 're: ', '', 'ig')), $3, $2);
			UPDATE peeps.emails SET answer_id=new_id, closed_at=NOW(), closed_by=$1 WHERE id=$2;
			status := 200;
			js := json_build_object('id', new_id);
		END IF;
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- GET /unknowns/count
-- PARAMS: emailer_id
CREATE OR REPLACE FUNCTION peeps.count_unknowns(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_build_object('count', (SELECT COUNT(*) FROM peeps.unknown_email_ids($1)));
END;
$$ LANGUAGE plpgsql;


-- GET /unknowns
-- PARAMS: emailer_id
CREATE OR REPLACE FUNCTION peeps.get_unknowns(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.emails_view WHERE id IN
		(SELECT * FROM peeps.unknown_email_ids($1))) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /unknowns/next
-- PARAMS: emailer_id
CREATE OR REPLACE FUNCTION peeps.get_next_unknown(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.unknown_view r
		WHERE id IN (SELECT * FROM peeps.unknown_email_ids($1) LIMIT 1);
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
END;
$$ LANGUAGE plpgsql;


-- POST /unknowns/:id?person_id=123 or 0 to create new
-- PARAMS: emailer_id, email_id, person_id
CREATE OR REPLACE FUNCTION peeps.set_unknown_person(integer, integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	this_e emails;
	newperson people;
	rowcount integer;
m4_ERRVARS
BEGIN
	SELECT * INTO this_e FROM peeps.emails WHERE id IN
		(SELECT * FROM peeps.unknown_email_ids($1)) AND id = $2;
	GET DIAGNOSTICS rowcount = ROW_COUNT;
	IF rowcount = 0 THEN m4_NOTFOUND RETURN; END IF;
	IF $3 = 0 THEN
		SELECT * INTO newperson FROM peeps.person_create(this_e.their_name, this_e.their_email);
	ELSE
		SELECT * INTO newperson FROM peeps.people WHERE id = $3;
		GET DIAGNOSTICS rowcount = ROW_COUNT;
		IF rowcount = 0 THEN m4_NOTFOUND RETURN; END IF;
		UPDATE peeps.people SET email=this_e.their_email,
			notes = concat('OLD EMAIL: ', email, E'\n', notes) WHERE id = $3;
	END IF;
	UPDATE peeps.emails SET person_id=newperson.id, category=profile WHERE id = $2;
	status := 200;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = $2;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- DELETE /unknowns/:id
-- PARAMS: emailer_id, email_id
CREATE OR REPLACE FUNCTION peeps.delete_unknown(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.unknown_view r
		WHERE id IN (SELECT * FROM peeps.unknown_email_ids($1)) AND id = $2;
	IF js IS NULL THEN
m4_NOTFOUND RETURN;
	ELSE
		DELETE FROM peeps.emails WHERE id = $2;
	END IF;
END;
$$ LANGUAGE plpgsql;

COMMIT;


-- POST /people
-- PARAMS: name, email
CREATE OR REPLACE FUNCTION peeps.create_person(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
m4_ERRVARS
BEGIN
	SELECT id INTO pid FROM peeps.person_create($1, $2);
	status := 200;
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = pid;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- POST /people/:id/newpass
-- PARAMS: person_id
CREATE OR REPLACE FUNCTION peeps.make_newpass(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE peeps.people
		SET newpass=core.unique_for_table_field(8, 'peeps.people', 'newpass')
		WHERE id = $1 AND newpass IS NULL;
	status := 200;
	SELECT json_build_object('id', id, 'newpass', newpass) INTO js
		FROM peeps.people WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /people/:id
-- PARAMS: person_id
CREATE OR REPLACE FUNCTION peeps.get_person(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = $1;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /people/:email
-- PARAMS: email
CREATE OR REPLACE FUNCTION peeps.get_person_email(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid FROM peeps.get_person_id_from_email($1);
	IF pid IS NULL THEN m4_NOTFOUND END IF;
	status := 200;
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = pid;
	IF js IS NULL THEN m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /people/:id/:lopass
-- PARAMS: person_id, lopass
CREATE OR REPLACE FUNCTION peeps.get_person_lopass(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid FROM peeps.people WHERE id=$1 AND lopass=$2;
	IF pid IS NULL THEN
m4_NOTFOUND
	ELSE
		SELECT x.status, x.js INTO status, js FROM peeps.get_person($1) x;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /people/:id/:newpass
-- PARAMS: person_id, newpass
CREATE OR REPLACE FUNCTION peeps.get_person_newpass(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid FROM peeps.people WHERE id=$1 AND newpass=$2;
	IF pid IS NULL THEN
m4_NOTFOUND
	ELSE
		SELECT x.status, x.js INTO status, js FROM peeps.get_person($1) x;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /people?email=&password=
-- PARAMS: email, password
CREATE OR REPLACE FUNCTION peeps.get_person_password(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT p.pid INTO pid FROM peeps.pid_from_email_pass($1, $2) p;
	IF pid IS NULL THEN
m4_NOTFOUND
	ELSE
		SELECT x.status, x.js INTO status, js FROM peeps.get_person(pid) x;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /person/{cookie}
-- PARAMS: cookie string
CREATE OR REPLACE FUNCTION peeps.get_person_cookie(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT p.id INTO pid FROM peeps.get_person_from_cookie($1) p;
	IF pid IS NULL THEN
m4_NOTFOUND
	ELSE
		SELECT x.status, x.js INTO status, js FROM peeps.get_person(pid) x;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- POST /login
-- PARAMS: person.id, domain
CREATE OR REPLACE FUNCTION peeps.cookie_from_id(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	status := 200;
	js := row_to_json(r) FROM (SELECT cookie FROM peeps.login_person_domain($1, $2)) r;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- POST /login
-- PARAMS: email, password, domain
CREATE OR REPLACE FUNCTION peeps.cookie_from_login(text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT p.pid INTO pid FROM peeps.pid_from_email_pass($1, $2) p;
	IF pid IS NULL THEN m4_NOTFOUND ELSE
		SELECT x.status, x.js INTO status, js FROM peeps.cookie_from_id(pid, $3) x;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PUT /people/:id/password
-- PARAMS: person_id, password
CREATE OR REPLACE FUNCTION peeps.set_password(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM peeps.set_hashpass($1, $2);
	SELECT x.status, x.js INTO status, js FROM peeps.get_person($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PUT /people/:id
-- PARAMS: person_id, JSON of new values
CREATE OR REPLACE FUNCTION peeps.update_person(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM core.jsonupdate('peeps.people', $1, $2,
		core.cols2update('peeps', 'people', ARRAY['id', 'created_at']));
	SELECT x.status, x.js INTO status, js FROM peeps.get_person($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- DELETE /people/:id
-- PARAMS: person_id
CREATE OR REPLACE FUNCTION peeps.delete_person(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = $1;
	IF js IS NULL THEN
m4_NOTFOUND
	ELSE
		DELETE FROM peeps.people WHERE id = $1;
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- DELETE /people/:id/annihilate
-- PARAMS: person_id
CREATE OR REPLACE FUNCTION peeps.annihilate_person(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	res RECORD;
m4_ERRVARS
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = $1;
	IF js IS NULL THEN
m4_NOTFOUND
	ELSE
		FOR res IN SELECT * FROM core.tables_referencing('peeps', 'people', 'id') LOOP
			EXECUTE format ('DELETE FROM %s WHERE %I=%s',
				res.tablename, res.colname, $1);
		END LOOP;
		DELETE FROM peeps.people WHERE id = $1;
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- POST /people/:id/urls
-- PARAMS: person_id, url
CREATE OR REPLACE FUNCTION peeps.add_url(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	status := 200;
	WITH nu AS (INSERT INTO urls(person_id, url)
		VALUES ($1, $2) RETURNING *)
		SELECT row_to_json(r.*) INTO js FROM nu r;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- POST /people/:id/stats
-- PARAMS: person_id, stat.name, stat.value
CREATE OR REPLACE FUNCTION peeps.add_stat(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	status := 200;
	WITH nu AS (INSERT INTO stats(person_id, statkey, statvalue)
		VALUES ($1, $2, $3) RETURNING *)
		SELECT row_to_json(r) INTO js FROM
			(SELECT id, created_at, statkey AS name, statvalue AS value FROM nu) r;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- POST /people/:id/emails
-- PARAMS: emailer_id, person_id, profile, subject, body
CREATE OR REPLACE FUNCTION peeps.new_email(integer, integer, text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	-- PARAMS: emailer_id, person_id, profile, category, subject, body, reference_id (NULL unless reply)
	SELECT * INTO new_id FROM peeps.outgoing_email($1, $2, $3, $3, $4, $5, NULL);
	status := 200;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = new_id;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- GET /people/:id/emails
-- PARAMS: person_id
CREATE OR REPLACE FUNCTION peeps.get_person_emails(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM
		(SELECT * FROM peeps.emails_full_view WHERE person_id = $1 ORDER BY id) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- POST /people/:id/merge?id=old_id
-- PARAMS: person_id to KEEP, person_id to CHANGE
CREATE OR REPLACE FUNCTION peeps.merge_person(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM person_merge_from_to($2, $1);
	status := 200;
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = $1;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- GET /people/unmailed
-- PARAMS: -none-
CREATE OR REPLACE FUNCTION peeps.people_unemailed(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.people_view
		WHERE email_count = 0 ORDER BY id DESC LIMIT 200) r;
END;
$$ LANGUAGE plpgsql;


-- GET /search?q=term
-- PARAMS: search term
CREATE OR REPLACE FUNCTION peeps.people_search(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	q text;
m4_ERRVARS
BEGIN
	q := concat('%', btrim($1, E'\t\r\n '), '%');
	IF LENGTH(q) < 4 THEN
		RAISE 'search term too short';
	END IF;
	status := 200;
	js := json_agg(r) FROM
		(SELECT * FROM peeps.people_view WHERE id IN (SELECT id FROM peeps.people
				WHERE name ILIKE q OR company ILIKE q OR email ILIKE q)
		ORDER BY email_count DESC, id DESC) r;
	IF js IS NULL THEN
		js := '{}';
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- GET /stats/:id
-- PARAMS: stats.id
CREATE OR REPLACE FUNCTION peeps.get_stat(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.stats_view r WHERE id=$1;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
END;
$$ LANGUAGE plpgsql;



-- PUT /stat/:id
-- PARAMS: stats.id, json
CREATE OR REPLACE FUNCTION peeps.update_stat(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM core.jsonupdate('peeps.stats', $1, $2,
		core.cols2update('peeps', 'stats', ARRAY['id', 'created_at']));
	status := 200;
	js := row_to_json(r.*) FROM peeps.stats_view r WHERE id=$1;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- DELETE /stats/:id
-- PARAMS: stats.id
CREATE OR REPLACE FUNCTION peeps.delete_stat(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.stats_view r WHERE id=$1;
	IF js IS NULL THEN
m4_NOTFOUND
	ELSE
		DELETE FROM peeps.stats WHERE id = $1;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /urls/:id
-- PARAMS: urls.id
CREATE OR REPLACE FUNCTION peeps.get_url(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.urls r WHERE id=$1;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
END;
$$ LANGUAGE plpgsql;


-- DELETE /urls/:id
-- PARAMS: urls.id
CREATE OR REPLACE FUNCTION peeps.delete_url(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.urls r WHERE id = $1;
	IF js IS NULL THEN
m4_NOTFOUND
	ELSE
		DELETE FROM peeps.urls WHERE id = $1;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PUT /urls/:id
-- PARAMS: urls.id, JSON with allowed: person_id::int, url::text, main::boolean
CREATE OR REPLACE FUNCTION peeps.update_url(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM core.jsonupdate('peeps.urls', $1, $2,
		core.cols2update('peeps', 'urls', ARRAY['id']));
	status := 200;
	js := row_to_json(r.*) FROM peeps.urls r WHERE id = $1;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- GET /formletters
-- PARAMS: -none-
CREATE OR REPLACE FUNCTION peeps.get_formletters(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM
		(SELECT * FROM peeps.formletters_view ORDER BY accesskey, title) r;
END;
$$ LANGUAGE plpgsql;


-- POST /formletters
-- PARAMS: title
CREATE OR REPLACE FUNCTION peeps.create_formletter(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
m4_ERRVARS
BEGIN
	INSERT INTO formletters(title) VALUES ($1) RETURNING id INTO new_id;
	status := 200;
	js := row_to_json(r.*) FROM peeps.formletter_view r WHERE id = new_id;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- GET /formletters/:id
-- PARAMS: formletters.id
CREATE OR REPLACE FUNCTION peeps.get_formletter(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.formletter_view r WHERE id = $1;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PUT /formletters/:id
-- PARAMS: formletters.id, JSON keys: title, explanation, body
CREATE OR REPLACE FUNCTION peeps.update_formletter(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM core.jsonupdate('peeps.formletters', $1, $2,
		core.cols2update('peeps', 'formletters', ARRAY['id', 'created_at']));
	status := 200;
	js := row_to_json(r.*) FROM peeps.formletter_view r WHERE id = $1;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- DELETE /formletters/:id
-- PARAMS: formletters.id
CREATE OR REPLACE FUNCTION peeps.delete_formletter(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*) FROM peeps.formletter_view r WHERE id = $1;
	IF js IS NULL THEN
m4_NOTFOUND
	ELSE
		DELETE FROM peeps.formletters WHERE id = $1;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- js = a simple JSON object: {"body": "The parsed text here, Derek."}
-- If wrong IDs given, value is null
-- GET /people/:id/formletters/:id
-- PARAMS: people.id, formletters.id
CREATE OR REPLACE FUNCTION peeps.parsed_formletter(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_build_object('body', parse_formletter_body($1, $2));
END;
$$ LANGUAGE plpgsql;


-- PARAMS: people.id, formletters.id, profile
CREATE OR REPLACE FUNCTION peeps.send_person_formletter(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
BEGIN
	-- outgoing_email params: emailer_id (2=robot), person_id, profile, category,
	-- subject, body, reference_id
	SELECT outgoing_email INTO email_id FROM peeps.outgoing_email(2, $1, $3, $3,
		(SELECT subject FROM peeps.parse_formletter_subject($1, $2)),
		(SELECT body FROM peeps.parse_formletter_body($1, $2)),
		NULL);
	status := 200;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = email_id;
END;
$$ LANGUAGE plpgsql;


-- sets newpass if none, sends email if not already sent recently
-- PARAMS: formletter.id, email address
CREATE OR REPLACE FUNCTION peeps.reset_email(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid FROM peeps.get_person_id_from_email($2);
	IF pid IS NULL THEN m4_NOTFOUND ELSE
		PERFORM peeps.make_newpass(pid);
		SELECT x.status, x.js INTO status, js FROM
			peeps.send_person_formletter(pid, $1, 'derek@sivers') x;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /locations
-- PARAMS: -none-
-- RETURNS array of objects:
-- [{"code":"AF","name":"Afghanistan"},{"code":"AX","name":"Åland Islands"}..]
CREATE OR REPLACE FUNCTION peeps.all_countries(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.countries ORDER BY name) r;
END;
$$ LANGUAGE plpgsql;


-- GET /country_names
-- PARAMS: -none-
-- RETURNS single code:name object:
-- {"AD":"Andorra","AE":"United Arab Emirates...  }
CREATE OR REPLACE FUNCTION peeps.country_names(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_object(
		ARRAY(SELECT code FROM countries ORDER BY code),
		ARRAY(SELECT name FROM countries ORDER BY code));
END;
$$ LANGUAGE plpgsql;


-- GET /countries
-- PARAMS: -none-
CREATE OR REPLACE FUNCTION peeps.country_count(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT country, COUNT(*) FROM peeps.people
		WHERE country IS NOT NULL GROUP BY country ORDER BY COUNT(*) DESC, country) r;
END;
$$ LANGUAGE plpgsql;


-- GET /states/:country_code
-- PARAMS: 2-letter country code
CREATE OR REPLACE FUNCTION peeps.state_count(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT state, COUNT(*) FROM peeps.people
		WHERE country = $1 AND state IS NOT NULL AND state != ''
		GROUP BY state ORDER BY COUNT(*) DESC, state) r;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /cities/:country_code/:state
-- PARAMS: 2-letter country code, state name
CREATE OR REPLACE FUNCTION peeps.city_count(char(2), text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT city, COUNT(*) FROM peeps.people
		WHERE country=$1 AND state=$2 AND (city IS NOT NULL AND city != '')
		GROUP BY city ORDER BY COUNT(*) DESC, city) r;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /cities/:country_code
-- PARAMS: 2-letter country code
CREATE OR REPLACE FUNCTION peeps.city_count(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT city, COUNT(*) FROM peeps.people
		WHERE country=$1 AND (city IS NOT NULL AND city != '')
		GROUP BY city ORDER BY COUNT(*) DESC, city) r;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /where/:country_code
-- PARAMS: 2-letter country code
CREATE OR REPLACE FUNCTION peeps.people_from_country(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.people_view WHERE id IN
		(SELECT id FROM peeps.people WHERE country=$1)
		ORDER BY email_count DESC, name) r;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /where/:country_code?state=XX
-- PARAMS: 2-letter country code, state
CREATE OR REPLACE FUNCTION peeps.people_from_state(char(2), text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.people_view WHERE id IN
		(SELECT id FROM peeps.people WHERE country=$1 AND state=$2)
		ORDER BY email_count DESC, name) r;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /where/:country_code?city=XX
-- PARAMS: 2-letter country code, state
CREATE OR REPLACE FUNCTION peeps.people_from_city(char(2), text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.people_view WHERE id IN
		(SELECT id FROM peeps.people WHERE country=$1 AND city=$2)
		ORDER BY email_count DESC, name) r;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /where/:country_code?city=XX&state=XX
-- PARAMS: 2-letter country code, state, city
CREATE OR REPLACE FUNCTION peeps.people_from_state_city(char(2), text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.people_view WHERE id IN
		(SELECT id FROM peeps.people WHERE country=$1 AND state=$2 AND city=$3)
		ORDER BY email_count DESC, name) r;
	IF js IS NULL THEN
m4_NOTFOUND
	END IF;
END;
$$ LANGUAGE plpgsql;



-- GET /stats/:key/:value
-- PARAMS: stats.name, stats.value
CREATE OR REPLACE FUNCTION peeps.get_stats(text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.stats_view
		WHERE name = $1 AND value = $2) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /stats/:key
-- PARAMS: stats.name
CREATE OR REPLACE FUNCTION peeps.get_stats(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.stats_view WHERE name = $1) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /statcount/:key
-- PARAMS: stats.name
CREATE OR REPLACE FUNCTION peeps.get_stat_value_count(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT statvalue AS value, COUNT(*) AS count
		FROM peeps.stats WHERE statkey=$1 GROUP BY statvalue ORDER BY statvalue) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /statcount
-- PARAMS: -none-
CREATE OR REPLACE FUNCTION peeps.get_stat_name_count(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT statkey AS name, COUNT(*) AS count
		FROM peeps.stats GROUP BY statkey ORDER BY statkey) r;
END;
$$ LANGUAGE plpgsql;


-- POST /email
-- PARAMS: json of values to insert
-- KEYS: profile category message_id their_email their_name subject headers body
CREATE OR REPLACE FUNCTION peeps.import_email(json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	eid integer;
	pid integer;
	rid integer;
m4_ERRVARS
BEGIN
	-- insert as-is (easier to update once in database)
	-- created_by = 2  TODO: created_by=NULL for imports?
	INSERT INTO peeps.emails(created_by, profile, category, message_id, their_email,
		their_name, subject, headers, body) SELECT 2 AS created_by, profile, category,
		message_id, their_email, their_name, subject, headers, body
		FROM json_populate_record(null::peeps.emails, $1) RETURNING id INTO eid;
	-- if references.message_id found, update person_id, reference_id, category
	IF json_array_length($1 -> 'references') > 0 THEN
		UPDATE peeps.emails SET person_id=ref.person_id, reference_id=ref.id,
			category = COALESCE(peeps.people.categorize_as, peeps.emails.profile)
			FROM peeps.emails ref, peeps.people
			WHERE peeps.emails.id=eid AND ref.person_id=peeps.people.id
			AND ref.message_id IN
				(SELECT * FROM json_array_elements_text($1 -> 'references'))
			RETURNING emails.person_id, ref.id INTO pid, rid;
		IF rid IS NOT NULL THEN
			UPDATE peeps.emails SET answer_id=eid WHERE id=rid;
		END IF;
	END IF;
	-- if their_email is found, update person_id, category
	IF pid IS NULL THEN
		UPDATE peeps.emails e SET person_id=p.id,
			category=COALESCE(p.categorize_as, e.profile)
			FROM peeps.people p WHERE e.id=eid
			AND (p.email=e.their_email OR p.company=e.their_email)
			RETURNING e.person_id INTO pid;
	END IF;
	-- if still not found, set category to fix-client (TODO: make this unnecessary)
	IF pid IS NULL THEN
		UPDATE peeps.emails SET category='fix-client' WHERE id=eid
			RETURNING person_id INTO pid;
	END IF;
	-- insert attachments
	IF json_array_length($1 -> 'attachments') > 0 THEN
		INSERT INTO email_attachments(email_id, mime_type, filename, bytes)
			SELECT eid AS email_id, mime_type, filename, bytes FROM
			json_populate_recordset(null::peeps.email_attachments, $1 -> 'attachments');
	END IF;
	status := 200;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id=eid;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- Update mailing list settings for this person (whether new or existing)
-- POST /list
-- PARAMS name, email, listype ($3 should be: 'all', 'some', 'none', or 'dead')
CREATE OR REPLACE FUNCTION peeps.list_update(text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
	clean3 text;
m4_ERRVARS
BEGIN
	clean3 := regexp_replace($3, '[^a-z]', '', 'g');
	SELECT id INTO pid FROM peeps.person_create($1, $2);
	INSERT INTO peeps.stats(person_id, statkey, statvalue)
		VALUES (pid, 'listype', clean3);
	UPDATE peeps.people SET listype=clean3 WHERE id=pid;
	status := 200;
	js := json_build_object('list', clean3);
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION peeps.queued_emails(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT e.id, e.profile, e.their_email,
		e.subject, e.body, e.message_id, ref.message_id AS referencing
		FROM peeps.emails e
		LEFT JOIN peeps.emails ref ON e.reference_id=ref.id
		WHERE e.outgoing IS NULL ORDER BY e.id) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: emails.id
CREATE OR REPLACE FUNCTION peeps.email_is_sent(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	status := 200;
	UPDATE peeps.emails SET outgoing=TRUE WHERE id=$1;
	IF FOUND THEN
		js := json_build_object('sent', $1);
	ELSE
m4_NOTFOUND
	END IF;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- GET /emails/sent
-- PARAMS: howmany
CREATE OR REPLACE FUNCTION peeps.sent_emails(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT * FROM peeps.emails_view WHERE id IN
		(SELECT id FROM peeps.emails WHERE outgoing IS TRUE ORDER BY id DESC LIMIT $1)
		ORDER BY id DESC) r;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: -none-
CREATE OR REPLACE FUNCTION peeps.sent_emails_grouped(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT p.id, p.name, (SELECT json_agg(x) AS sent FROM
		(SELECT id, subject, created_at, their_name, their_email FROM peeps.emails
			WHERE closed_by=e.id AND outgoing IS TRUE
			AND closed_at > (NOW() - interval '9 days')
			ORDER BY id DESC) x)
	FROM peeps.emailers e, peeps.people p
	WHERE e.person_id=p.id AND e.id IN (SELECT DISTINCT(created_by) FROM emails
		WHERE closed_at > (NOW() - interval '9 days') AND outgoing IS TRUE)
		ORDER BY e.id DESC) r;
END;
$$ LANGUAGE plpgsql;


-- Array of {person_id: 1234, twitter: 'username'}
CREATE OR REPLACE FUNCTION peeps.twitter_unfollowed(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT person_id,
		regexp_replace(regexp_replace(url, 'https?://twitter.com/', ''), '/$', '')
		AS twitter FROM peeps.urls WHERE url LIKE '%twitter.com%'
		AND person_id NOT IN
			(SELECT person_id FROM peeps.stats WHERE statkey='twitter')) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- Mark this a dead email - by ID
-- PARAMS: person_id
CREATE OR REPLACE FUNCTION peeps.dead_email(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE peeps.people SET email=NULL, listype=NULL,
		notes=CONCAT('DEAD EMAIL: ', email, E'\n', notes)
		WHERE id = $1 AND email IS NOT NULL;
	IF FOUND THEN
		status := 200;
		js := json_build_object('ok', $1);
	ELSE m4_NOTFOUND END IF;
END;
$$ LANGUAGE plpgsql;


-- ARRAY of schema.tablenames where with this person_id
-- PARAMS: person_id
CREATE OR REPLACE FUNCTION peeps.tables_with_person(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	res RECORD;
	tablez text[] := ARRAY[]::text[];
	rowcount integer;
BEGIN
	FOR res IN SELECT * FROM core.tables_referencing('peeps', 'people', 'id') LOOP
		EXECUTE format ('SELECT 1 FROM %s WHERE %I=%s',
			res.tablename, res.colname, $1);
		GET DIAGNOSTICS rowcount = ROW_COUNT;
		IF rowcount > 0 THEN
			tablez := tablez || res.tablename;
		END IF;
	END LOOP;
	status := 200;
	js := array_to_json(tablez);
END;
$$ LANGUAGE plpgsql;


-- Array of people's [[id, email, address, lopass]] for emailing
-- PARAMS: key,val to be used in WHERE _key_ = _val_
CREATE OR REPLACE FUNCTION peeps.ieal_where(text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	EXECUTE format ('SELECT json_agg(j) FROM
		(SELECT json_build_array(id, email, address, lopass) AS j
		FROM peeps.people WHERE email IS NOT NULL
		AND %I=%L ORDER BY id) r', $1, $2) INTO js;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS person_id, schema, table, id
CREATE OR REPLACE FUNCTION peeps.log(integer, text, text, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := '{}';
	INSERT INTO core.changelog(person_id, schema_name, table_name, table_id)
		VALUES($1, $2, $3, $4);
END;
$$ LANGUAGE plpgsql;


-- awaiting changelog by group
CREATE OR REPLACE FUNCTION peeps.inspections_grouped(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT schema_name, table_name, COUNT(*)
		FROM core.changelog WHERE approved IS FALSE
		GROUP BY schema_name, table_name) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION peeps.inspect_peeps_people(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT c.id, c.person_id, city, state, country, email
		FROM core.changelog c LEFT JOIN peeps.people p
		ON c.table_id=p.id WHERE c.approved IS FALSE
		AND schema_name='peeps' AND table_name='people') r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION peeps.inspect_peeps_urls(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT c.id, c.person_id, url
		FROM core.changelog c LEFT JOIN peeps.urls u
		ON c.table_id=u.id WHERE c.approved IS FALSE
		AND schema_name='peeps' AND table_name='urls') r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION peeps.inspect_peeps_stats(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT c.id, c.person_id, statkey, statvalue
		FROM core.changelog c LEFT JOIN peeps.stats s
		ON c.table_id=s.id WHERE c.approved IS FALSE
		AND schema_name='peeps' AND table_name='stats') r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION peeps.inspect_now_urls(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT c.id, c.person_id, short, long
		FROM core.changelog c LEFT JOIN now.urls u
		ON c.table_id=u.id WHERE c.approved IS FALSE
		AND schema_name='now' AND table_name='urls') r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- TODO: cast JSON array elements as ::integer instead of casting id::text
-- PARAMS: JSON array of integer ids: core.changelog.id
CREATE OR REPLACE FUNCTION peeps.log_approve(json,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE core.changelog SET approved=TRUE WHERE id::text IN
		(SELECT * FROM json_array_elements_text($1));
	status := 200;
	js := '{}';
END;
$$ LANGUAGE plpgsql;


-- *all* attribute keys, sorted, and if we have attributes for this person,
-- then those values are here, but returns null values for any not found
-- PARAMS: person_id
CREATE OR REPLACE FUNCTION peeps.person_attributes(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT atkey, plusminus FROM peeps.atkeys
		LEFT JOIN peeps.attributes ON
			(peeps.atkeys.atkey=peeps.attributes.attribute
				AND peeps.attributes.person_id=$1)
		ORDER BY peeps.atkeys.atkey) r;
END;
$$ LANGUAGE plpgsql;


-- list of interests and boolean expert flag (not null) for person_id
-- expertises first, wantings last
-- PARAMS: person_id
CREATE OR REPLACE FUNCTION peeps.person_interests(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT interest, expert
		FROM peeps.interests WHERE person_id=$1
		ORDER BY expert DESC, interest ASC) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: person_id, attribute, plusminus
CREATE OR REPLACE FUNCTION peeps.person_set_attribute(integer, text, boolean,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE peeps.attributes SET plusminus=$3 WHERE person_id=$1 AND attribute=$2;
	IF NOT FOUND THEN
		INSERT INTO peeps.attributes VALUES ($1, $2, $3);
	END IF;
	SELECT x.status, x.js INTO status, js FROM peeps.person_attributes($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: person_id, attribute
CREATE OR REPLACE FUNCTION peeps.person_delete_attribute(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	DELETE FROM peeps.attributes WHERE person_id=$1 AND attribute=$2;
	SELECT x.status, x.js INTO status, js FROM peeps.person_attributes($1) x;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: person_id, interest
CREATE OR REPLACE FUNCTION peeps.person_add_interest(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	PERFORM 1 FROM peeps.interests WHERE person_id=$1 AND interest=$2;
	IF NOT FOUND THEN
		INSERT INTO peeps.interests(person_id, interest) VALUES ($1, $2);
	END IF;
	SELECT x.status, x.js INTO status, js FROM peeps.person_interests($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: person_id, interest, expert (set expert flag to existing)
CREATE OR REPLACE FUNCTION peeps.person_update_interest(integer, text, boolean,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE peeps.interests SET expert=$3 WHERE person_id=$1 AND interest=$2;
	SELECT x.status, x.js INTO status, js FROM peeps.person_interests($1) x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: person_id, interest
CREATE OR REPLACE FUNCTION peeps.person_delete_interest(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	DELETE FROM peeps.interests WHERE person_id=$1 AND interest=$2;
	SELECT x.status, x.js INTO status, js FROM peeps.person_interests($1) x;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: -none-
CREATE OR REPLACE FUNCTION peeps.attribute_keys(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT atkey, description
		FROM peeps.atkeys ORDER BY atkey) r;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: atkey
CREATE OR REPLACE FUNCTION peeps.add_attribute_key(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	INSERT INTO peeps.atkeys(atkey) VALUES ($1);
	SELECT x.status, x.js INTO status, js FROM peeps.attribute_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: atkey
CREATE OR REPLACE FUNCTION peeps.delete_attribute_key(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	DELETE FROM peeps.atkeys WHERE atkey=$1;
	SELECT x.status, x.js INTO status, js FROM peeps.attribute_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: atkey, description
CREATE OR REPLACE FUNCTION peeps.update_attribute_key(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE peeps.atkeys SET description=$2 WHERE atkey=$1;
	SELECT x.status, x.js INTO status, js FROM peeps.attribute_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: -none-
CREATE OR REPLACE FUNCTION peeps.interest_keys(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT inkey, description
		FROM peeps.inkeys ORDER BY inkey) r;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: inkey
CREATE OR REPLACE FUNCTION peeps.add_interest_key(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	INSERT INTO peeps.inkeys(inkey) VALUES ($1);
	SELECT x.status, x.js INTO status, js FROM peeps.interest_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: inkey
CREATE OR REPLACE FUNCTION peeps.delete_interest_key(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	DELETE FROM peeps.inkeys WHERE inkey=$1;
	SELECT x.status, x.js INTO status, js FROM peeps.interest_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- PARAMS: inkey, description
CREATE OR REPLACE FUNCTION peeps.update_interest_key(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
m4_ERRVARS
BEGIN
	UPDATE peeps.inkeys SET description=$2 WHERE inkey=$1;
	SELECT x.status, x.js INTO status, js FROM peeps.interest_keys() x;
m4_ERRCATCH
END;
$$ LANGUAGE plpgsql;


-- Finds interest words in email body that are not yet in person's interests
-- PARAMS: email_id
CREATE OR REPLACE FUNCTION peeps.interests_in_email(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := to_json(ARRAY(SELECT inkey FROM peeps.inkeys
		WHERE inkey IN (SELECT regexp_split_to_table(lower(body), '[^a-z]+')
			FROM peeps.emails WHERE id = $1)
		AND inkey NOT IN (SELECT interest FROM peeps.interests
			JOIN peeps.emails ON peeps.emails.person_id=peeps.interests.person_id
			WHERE peeps.emails.id = $1
		ORDER BY inkey)));
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- Total time in the last 3 months this emailer spent on open emails
-- JSON format: {'2016-02': '06:20:29'
-- PARAMS: emailer_id
CREATE OR REPLACE FUNCTION peeps.emailer_times(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	month1 text;
	month2 text;
	month3 text;
BEGIN
	SELECT SUBSTRING(date_trunc('month', now())::text from 1 for 7) INTO month1;
	SELECT SUBSTRING(date_trunc('month', (now() - interval '1 month'))::text from 1 for 7) INTO month2;
	SELECT SUBSTRING(date_trunc('month', (now() - interval '2 month'))::text from 1 for 7) INTO month3;
	status := 200;
	js := json_build_object(
		month1,
		peeps.etimes_in_month($1, month1 || '-01'),
		month2,
		peeps.etimes_in_month($1, month2 || '-01'),
		month3,
		peeps.etimes_in_month($1, month3 || '-01'));
END;
$$ LANGUAGE plpgsql;


-- Total time per day this emailer spent on open emails per-day in this month
-- JSON format: [{"day":"2015-12-23","hhmm":"02:42"},...]
-- PARAMS: emailer_id, month in format '2015-12' 
CREATE OR REPLACE FUNCTION peeps.emailer_times_per_day(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT
		substring(date_trunc('day', closed_at)::text from 1 for 10) AS day,
		substring(SUM(closed_at - opened_at)::text from 1 for 5) AS hhmm
		FROM peeps.emails WHERE outgoing IS FALSE
		AND closed_by = $1
		AND date_trunc('month', closed_at) = ($2 || '-01')::date
		GROUP BY day ORDER BY day) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- array of emailer_id and name of active emailers in last 3 months
-- JSON format: [{'id':1, 'name':'Derek Sivers'}]
-- PARAMS: -none-
CREATE OR REPLACE FUNCTION peeps.active_emailers(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT DISTINCT(emails.closed_by) AS id, people.name
		FROM peeps.emails
		JOIN peeps.emailers ON peeps.emails.closed_by=peeps.emailers.id
		JOIN peeps.people ON peeps.emailers.person_id=peeps.people.id
		WHERE emails.closed_at > (NOW() - interval '3 months')
		AND emails.closed_by != 2
		ORDER BY emails.closed_by) r;
END;
$$ LANGUAGE plpgsql;

