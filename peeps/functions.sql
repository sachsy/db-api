----------------------------
----------- peeps FUNCTIONS:
---- (many just generic use)
----------------------------

-- pgcrypto for people.hashpass
CREATE OR REPLACE FUNCTION peeps.crypt(text, text) RETURNS text AS '$libdir/pgcrypto', 'pg_crypt' LANGUAGE c IMMUTABLE STRICT;
CREATE OR REPLACE FUNCTION peeps.gen_salt(text, integer) RETURNS text AS '$libdir/pgcrypto', 'pg_gen_salt_rounds' LANGUAGE c STRICT;


-- Use this to add a new person to the database.  Ensures unique email without clash.
-- USAGE: SELECT * FROM person_create('Dude Abides', 'dude@abid.es');
-- Will always return peeps.people row, whether new INSERT or existing SELECT
CREATE OR REPLACE FUNCTION peeps.person_create(new_name text, new_email text) RETURNS SETOF peeps.people AS $$
DECLARE
	clean_email text;
BEGIN
	clean_email := lower(regexp_replace(new_email, '\s', '', 'g'));
	IF clean_email IS NULL OR clean_email = '' THEN
		RAISE 'missing_email';
	END IF;
	IF NOT EXISTS (SELECT 1 FROM peeps.people WHERE email = clean_email) THEN
		RETURN QUERY INSERT INTO peeps.people (name, email) VALUES (new_name, clean_email) RETURNING peeps.people.*;
	ELSE
		RETURN QUERY SELECT * FROM peeps.people WHERE email = clean_email;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- Use this for user choosing their own password.
-- USAGE: SELECT set_hashpass(123, 'Th€IR nü FunK¥(!) pá$$werđ');
-- Returns false if that peeps.people.id doesn't exist, otherwise true.
CREATE OR REPLACE FUNCTION peeps.set_hashpass(person_id integer, password text) RETURNS boolean AS $$
BEGIN
	IF password IS NULL OR length(btrim(password)) < 4 THEN
		RAISE 'short_password';
	END IF;
	UPDATE peeps.people SET newpass=NULL,
		hashpass=peeps.crypt(password, peeps.gen_salt('bf', 8)) WHERE id = person_id;
	IF FOUND THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- For signups where new user gives name, email, AND password at once.
-- Don't want to set password if email already exists in system, otherwise attacker
-- could use it to change someone's password. So check existence first, then create.
-- If email/person exists already, just return person. Don't change password.
-- PARAMS: name, email, password
CREATE OR REPLACE FUNCTION peeps.person_create_pass(text, text, text) RETURNS SETOF peeps.people AS $$
DECLARE
	clean_email text;
	pid integer;
BEGIN
	clean_email := lower(regexp_replace($2, '\s', '', 'g'));
	IF clean_email IS NULL OR clean_email = '' THEN
		RAISE 'missing_email';
	END IF;
	SELECT id INTO pid FROM peeps.people WHERE email = clean_email;
	IF pid IS NULL THEN
		SELECT id INTO pid FROM peeps.person_create($1, $2);
		PERFORM peeps.set_hashpass(pid, $3);
	END IF;
	RETURN QUERY SELECT * FROM peeps.people WHERE id = pid;
END;
$$ LANGUAGE plpgsql;


-- Use this when a user is logging in with their email and (their own chosen) password.
-- USAGE: SELECT * FROM person_email_pass('dude@abid.es', 'Th€IR öld FunK¥ pá$$werđ');
-- Returns peeps.people.* if both are correct, or nothing if not.
-- Once authorized here, give logins or api_key cookie for future lookups.
CREATE OR REPLACE FUNCTION peeps.person_email_pass(my_email text, my_pass text) RETURNS SETOF peeps.people AS $$
DECLARE
	clean_email text;
BEGIN
	clean_email := lower(regexp_replace(my_email, '\s', '', 'g'));
	IF clean_email !~ '\A\S+@\S+\.\S+\Z' THEN
		RAISE 'bad_email';
	END IF;
	IF my_pass IS NULL OR length(btrim(my_pass)) < 4 THEN
		RAISE 'short_password';
	END IF;
	RETURN QUERY SELECT * FROM peeps.people WHERE email=clean_email AND hashpass=peeps.crypt(my_pass, hashpass);
END;
$$ LANGUAGE plpgsql;


-- When a person has multiple entries in peeps.people, merge two into one, updating foreign keys.
-- USAGE: SELECT person_merge_from_to(5432, 4321);
-- Returns array of tables actually updated in schema.table format like {'muckwork.clients', 'sivers.comments'}
-- (Return value is probably unneeded, but here it is anyway, just in case.)
CREATE OR REPLACE FUNCTION peeps.person_merge_from_to(old_id integer, new_id integer) RETURNS text[] AS $$
DECLARE
	res RECORD;
	done_tables text[] := ARRAY[]::text[];
	rowcount integer;
	old_p peeps.people;
	new_p peeps.people;
	move_public_id text;
BEGIN
	-- update ids to point to new one
	FOR res IN SELECT * FROM core.tables_referencing('peeps', 'people', 'id') LOOP
		EXECUTE format ('UPDATE %s SET %I=%s WHERE %I=%s',
			res.tablename, res.colname, new_id, res.colname, old_id);
		GET DIAGNOSTICS rowcount = ROW_COUNT;
		IF rowcount > 0 THEN
			done_tables := done_tables || res.tablename;
		END IF;
	END LOOP;
	SELECT * INTO old_p FROM peeps.people WHERE id = old_id;
	SELECT * INTO new_p FROM peeps.people WHERE id = new_id;
	-- if both have a public_id, we've got a problem
	IF LENGTH(old_p.public_id) = 4 AND LENGTH(new_p.public_id) = 4 THEN
		RAISE 'both_have_public_id';
	END IF;
	-- copy better(longer) data from old to new
	-- public_id, company, city, state, country, phone, categorize_as
	IF COALESCE(LENGTH(old_p.public_id), 0) > COALESCE(LENGTH(new_p.public_id), 0) THEN
		move_public_id := old_p.public_id; -- because must be unique:
		UPDATE peeps.people SET public_id = NULL WHERE id = old_id;
		UPDATE peeps.people SET public_id = move_public_id WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_p.company), 0) > COALESCE(LENGTH(new_p.company), 0) THEN
		UPDATE peeps.people SET company = old_p.company WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_p.city), 0) > COALESCE(LENGTH(new_p.city), 0) THEN
		UPDATE peeps.people SET city = old_p.city WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_p.state), 0) > COALESCE(LENGTH(new_p.state), 0) THEN
		UPDATE peeps.people SET state = old_p.state WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_p.country), 0) > COALESCE(LENGTH(new_p.country), 0) THEN
		UPDATE peeps.people SET country = old_p.country WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_p.phone), 0) > COALESCE(LENGTH(new_p.phone), 0) THEN
		UPDATE peeps.people SET phone = old_p.phone WHERE id = new_id;
	END IF;
	IF COALESCE(LENGTH(old_p.categorize_as), 0) > COALESCE(LENGTH(new_p.categorize_as), 0) THEN
		UPDATE peeps.people SET categorize_as = old_p.categorize_as WHERE id = new_id;
	END IF;
	IF LENGTH(old_p.notes) > 0 THEN  -- combine notes
		UPDATE peeps.people SET notes = CONCAT(old_p.notes, E'\n', notes) WHERE id = new_id;
	END IF;
	-- Done! delete old one
	DELETE FROM peeps.people WHERE id = old_id;
	RETURN done_tables;
END;
$$ LANGUAGE plpgsql;


-- Returns emails.* only if emailers.profiles && emailers.cateories matches
CREATE OR REPLACE FUNCTION peeps.emailer_get_email(emailer_id integer, email_id integer) RETURNS SETOF peeps.emails AS $$
DECLARE
	emailer peeps.emailers;
	email peeps.emails;
BEGIN
	SELECT * INTO emailer FROM peeps.emailers WHERE id = emailer_id;
	SELECT * INTO email FROM peeps.emails WHERE id = email_id;
	IF (emailer.profiles = '{ALL}' AND emailer.categories = '{ALL}') OR
	   (emailer.profiles = '{ALL}' AND email.category = ANY(emailer.categories)) OR
	   (email.profile = ANY(emailer.profiles) AND emailer.categories = '{ALL}') OR
	   (email.profile = ANY(emailer.profiles) AND email.category = ANY(emailer.categories)) THEN
		RETURN QUERY SELECT * FROM peeps.emails WHERE id = email_id;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- Returns unopened emails.* that this emailer is authorized to see
CREATE OR REPLACE FUNCTION peeps.emailer_get_unopened(emailer_id integer) RETURNS SETOF peeps.emails AS $$
DECLARE
	qry text := 'SELECT * FROM peeps.emails WHERE opened_at IS NULL AND person_id IS NOT NULL';
	emailer peeps.emailers;
BEGIN
	SELECT * INTO emailer FROM peeps.emailers WHERE id = emailer_id;
	IF (emailer.profiles != '{ALL}') THEN
		qry := qry || ' AND profile IN (SELECT UNNEST(profiles) FROM peeps.emailers WHERE id=' || emailer_id || ')';
	END IF;
	IF (emailer.categories != '{ALL}') THEN
		qry := qry || ' AND category IN (SELECT UNNEST(categories) FROM peeps.emailers WHERE id=' || emailer_id || ')';
	END IF;
	qry := qry || ' ORDER BY id ASC';
	RETURN QUERY EXECUTE qry;
END;
$$ LANGUAGE plpgsql;


-- Once a person has correctly given their email and password, call this to create cookie info.
-- Returns a single 65-character string, ready to be set as the cookie value
CREATE OR REPLACE FUNCTION peeps.login_person_domain(my_person_id integer, my_domain text, OUT cookie text) RETURNS text AS $$
DECLARE
	c_id text;
	c_tok text;
	c_exp integer;
BEGIN
	c_id := md5(my_domain || md5(my_person_id::text)); -- also in get_person_from_cookie
	c_tok := core.random_string(32);
	c_exp := FLOOR(EXTRACT(epoch from (NOW() + interval '1 year')));
	INSERT INTO peeps.logins(person_id, cookie_id, cookie_tok, cookie_exp, domain) VALUES (my_person_id, c_id, c_tok, c_exp, my_domain);
	cookie := CONCAT(c_id, ':', c_tok);
END;
$$ LANGUAGE plpgsql;


-- PARAMS: email
-- RETURNS: peeps.people.id or NULL
CREATE OR REPLACE FUNCTION peeps.get_person_id_from_email(text, OUT id integer) AS $$
DECLARE
	clean_email text;
BEGIN
	id := NULL;
	IF $1 IS NULL THEN RETURN; END IF;
	clean_email := lower(regexp_replace($1, '\s', '', 'g'));
	IF clean_email !~ '\A\S+@\S+\.\S+\Z' THEN RETURN; END IF;
	SELECT p.id INTO id FROM peeps.people p WHERE email = clean_email;
END;
$$ LANGUAGE plpgsql;


-- Give the cookie value returned from login_person_domain, and I'll return people.* if found and not expired
CREATE OR REPLACE FUNCTION peeps.get_person_from_cookie(cookie text) RETURNS SETOF peeps.people AS $$
DECLARE
	c_id text;
	c_tok text;
	a_login peeps.logins;
BEGIN
	c_id := split_part(cookie, ':', 1);
	c_tok := split_part(cookie, ':', 2);
	SELECT * INTO a_login FROM peeps.logins WHERE cookie_id=c_id AND cookie_tok=c_tok;
	IF FOUND AND
	  a_login.cookie_exp > FLOOR(EXTRACT(epoch from NOW())) AND
	  c_id = md5(a_login.domain || md5(a_login.person_id::text)) THEN
		RETURN QUERY SELECT * FROM peeps.people WHERE id=a_login.person_id;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- ids of unopened emails this emailer is allowed to access
-- PARAMS: emailer_id
CREATE OR REPLACE FUNCTION peeps.unopened_email_ids(integer) RETURNS SETOF integer AS $$
DECLARE
	pros text[];
	cats text[];
BEGIN
	SELECT profiles, categories INTO pros, cats FROM peeps.emailers WHERE id = $1;
	IF pros = array['ALL'] AND cats = array['ALL'] THEN
		RETURN QUERY SELECT id FROM peeps.emails WHERE opened_by IS NULL
			AND person_id IS NOT NULL ORDER BY id;
	ELSIF cats = array['ALL'] THEN
		RETURN QUERY SELECT id FROM peeps.emails WHERE opened_by IS NULL
			AND person_id IS NOT NULL AND profile = ANY(pros) ORDER BY id;
	ELSIF pros = array['ALL'] THEN
		RETURN QUERY SELECT id FROM peeps.emails WHERE opened_by IS NULL
			AND person_id IS NOT NULL AND category = ANY(cats) ORDER BY id;
	ELSE
		RETURN QUERY SELECT id FROM peeps.emails WHERE opened_by IS NULL
			AND person_id IS NOT NULL
			AND profile = ANY(pros) AND category = ANY(cats) ORDER BY id;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- ids of already-open emails this emailer is allowed to access
-- PARAMS: emailer_id
CREATE OR REPLACE FUNCTION peeps.opened_email_ids(integer) RETURNS SETOF integer AS $$
DECLARE
	pros text[];
	cats text[];
BEGIN
	SELECT profiles, categories INTO pros, cats FROM peeps.emailers WHERE id = $1;
	IF pros = array['ALL'] AND cats = array['ALL'] THEN
		RETURN QUERY SELECT id FROM peeps.emails WHERE opened_by IS NOT NULL
			AND closed_at IS NULL ORDER BY id;
	ELSIF cats = array['ALL'] THEN
		RETURN QUERY SELECT id FROM peeps.emails WHERE opened_by IS NOT NULL
			AND closed_at IS NULL AND profile = ANY(pros) ORDER BY id;
	ELSIF pros = array['ALL'] THEN
		RETURN QUERY SELECT id FROM peeps.emails WHERE opened_by IS NOT NULL
			AND closed_at IS NULL AND category = ANY(cats) ORDER BY id;
	ELSE
		RETURN QUERY SELECT id FROM peeps.emails WHERE opened_by IS NOT NULL
			AND closed_at IS NULL
			AND profile = ANY(pros) AND category = ANY(cats) ORDER BY id;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- ids of unknown-person emails, if this emailer is admin or allowed
-- (unknown-person emails don't have categories, so not checking for that)
-- PARAMS: emailer_id
CREATE OR REPLACE FUNCTION peeps.unknown_email_ids(integer) RETURNS SETOF integer AS $$
DECLARE
	pros text[];
BEGIN
	SELECT profiles INTO pros FROM peeps.emailers WHERE id = $1;
	IF pros = array['ALL'] THEN
		RETURN QUERY SELECT id FROM peeps.emails WHERE person_id IS NULL ORDER BY id;
	ELSE
		RETURN QUERY SELECT id FROM peeps.emails WHERE person_id IS NULL
			 AND profile = ANY(pros) ORDER BY id;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- If this emailer is allowed to see this email,
-- Returns email.id if found and permission granted, NULL if not
-- PARAMS: emailer_id, email_id
CREATE OR REPLACE FUNCTION peeps.ok_email(integer, integer) RETURNS integer AS $$
DECLARE
	pros text[];
	cats text[];
	eid integer;
BEGIN
	SELECT profiles, categories INTO pros, cats FROM peeps.emailers WHERE id = $1;
	IF pros = array['ALL'] AND cats = array['ALL'] THEN
		SELECT id INTO eid FROM peeps.emails WHERE id = $2;
	ELSIF cats = array['ALL'] THEN
		SELECT id INTO eid FROM peeps.emails WHERE id = $2 AND profile = ANY(pros);
	ELSIF pros = array['ALL'] THEN
		SELECT id INTO eid FROM peeps.emails WHERE id = $2 AND category = ANY(cats);
	ELSE
		SELECT id INTO eid FROM peeps.emails WHERE id = $2
			AND profile = ANY(pros) AND category = ANY(cats);
	END IF;
	RETURN eid;
END;
$$ LANGUAGE plpgsql;


-- Update it to be shown as opened_by this emailer now (if not already open)
-- Returns email.id if found and permission granted, NULL if not
-- PARAMS: emailer_id, email_id
CREATE OR REPLACE FUNCTION peeps.open_email(integer, integer) RETURNS integer AS $$
DECLARE
	ok_id integer;
BEGIN
	ok_id := ok_email($1, $2);
	IF ok_id IS NOT NULL THEN
		UPDATE peeps.emails SET opened_at=NOW(), opened_by=$1
			WHERE id=ok_id AND opened_by IS NULL;
	END IF;
	RETURN ok_id;
END;
$$ LANGUAGE plpgsql;


-- Create a new outging email
-- PARAMS: emailer_id, person_id, profile, category, subject, body, reference_id (NULL unless reply)
CREATE OR REPLACE FUNCTION peeps.outgoing_email(integer, integer, text, text, text, text, integer) RETURNS integer AS $$
DECLARE
	p peeps.people;
	rowcount integer;
	e peeps.emails;
	greeting text;
	signature text;
	new_body text;
	opt_headers text;
	old_body text;
	new_id integer;
BEGIN
	-- VERIFY INPUT:
	SELECT * INTO p FROM peeps.people WHERE id = $2;
	GET DIAGNOSTICS rowcount = ROW_COUNT;
	IF rowcount = 0 THEN
		RAISE 'person_id not found';
	END IF;
	CASE $3 WHEN 'we@woodegg' THEN
		signature := 'Wood Egg  we@woodegg.com  http://woodegg.com/';
	WHEN 'derek@sivers' THEN
		signature := 'Derek Sivers  derek@sivers.org  http://sivers.org/';
	ELSE
		RAISE 'invalid profile';
	END CASE;
	IF $4 IS NULL OR (regexp_replace($4, '\s', '', 'g') = '') THEN
		RAISE 'category must not be empty';
	END IF;
	IF $5 IS NULL OR (regexp_replace($5, '\s', '', 'g') = '') THEN
		RAISE 'subject must not be empty';
	END IF;
	IF $6 IS NULL OR (regexp_replace($6, '\s', '', 'g') = '') THEN
		RAISE 'body must not be empty';
	END IF;
	IF $7 IS NOT NULL THEN SELECT
		CONCAT('References: <', message_id, E'>\nIn-Reply-To: <', message_id, '>'),
		CONCAT(E'\n\n', regexp_replace(body, '^', '> ', 'ng'))
		INTO opt_headers, old_body FROM peeps.emails WHERE id = $7;
	END IF;
	-- START CREATING EMAIL:
	greeting := concat('Hi ', p.address);
	new_body := concat(greeting, E' -\n\n', $6, E'\n\n--\n', signature, old_body);
	EXECUTE 'INSERT INTO peeps.emails (person_id, outgoing, their_email, their_name,'
		|| ' created_at, created_by, opened_at, opened_by, closed_at, closed_by,'
		|| ' profile, category, subject, body, headers, reference_id) VALUES'
		|| ' ($1, NULL, $2, $3,'  -- outgoing = NULL = queued for sending
		|| ' NOW(), $4, NOW(), $5, NOW(), $6,'
		|| ' $7, $8, $9, $10, $11, $12) RETURNING id' INTO new_id
		USING p.id, p.email, p.name,
			$1, $1, $1,
			$3, $4, $5, new_body, opt_headers, $7;
	RETURN new_id;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: people.id, formletters.id
CREATE OR REPLACE FUNCTION peeps.parse_formletter_body(integer, integer,
	OUT body text) AS $$
DECLARE
	thisvar text;
	thisval text;
BEGIN
	SELECT f.body INTO body FROM peeps.formletters f WHERE id = $2;
	FOR thisvar IN SELECT regexp_matches(f.body, '{([^}]+)}', 'g')
		FROM peeps.formletters f WHERE id = $2 LOOP
		EXECUTE format ('SELECT %s::text FROM peeps.people WHERE id=%L',
			btrim(thisvar, '{}'), $1) INTO thisval;
		body := replace(body, thisvar, thisval);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: people.id, formletters.id
CREATE OR REPLACE FUNCTION peeps.parse_formletter_subject(integer, integer,
	OUT subject text) AS $$
DECLARE
	thisvar text;
	thisval text;
BEGIN
	SELECT f.subject INTO subject FROM peeps.formletters f WHERE id = $2;
	FOR thisvar IN SELECT regexp_matches(f.subject, '{([^}]+)}', 'g')
		FROM peeps.formletters f WHERE id = $2 LOOP
		EXECUTE format ('SELECT %s::text FROM peeps.people WHERE id=%L',
			btrim(thisvar, '{}'), $1) INTO thisval;
		subject := replace(subject, thisvar, thisval);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: email, password
CREATE OR REPLACE FUNCTION peeps.pid_from_email_pass(text, text, OUT pid integer) AS $$
DECLARE
	clean_email text;
BEGIN
	IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
		clean_email := lower(regexp_replace($1, '\s', '', 'g'));
		IF clean_email ~ '\A\S+@\S+\.\S+\Z' AND LENGTH($2) > 3 THEN
			SELECT id INTO pid FROM peeps.people
				WHERE email=clean_email AND hashpass=peeps.crypt($2, hashpass);
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: twitter handle like '@whatEver' (with or without @)
CREATE OR REPLACE FUNCTION peeps.pid_for_twitter_handle(text, OUT pid integer) AS $$
BEGIN
	SELECT person_id INTO pid FROM peeps.urls
		WHERE url LIKE '%/twitter.com/%'
		AND lower(regexp_replace(url, '^.*/', '')) = lower(replace($1, '@', ''))
		ORDER BY id ASC LIMIT 1;
END;
$$ LANGUAGE plpgsql;


-- Time this emailer spent on open emails in this month
-- PARAMS: emailer_id, month string like '2016-08-01' (always '-01' at end)
CREATE OR REPLACE FUNCTION peeps.etimes_in_month(integer, text, OUT total text) AS $$
BEGIN
	SELECT substring(SUM(closed_at - opened_at)::text from 1 for 5) INTO total
		FROM peeps.emails
		WHERE outgoing IS FALSE
		AND closed_by=$1
		AND date_trunc('month', closed_at) = $2::date;
END;
$$ LANGUAGE plpgsql;

