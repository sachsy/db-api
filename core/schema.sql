SET client_min_messages TO ERROR;
SET client_encoding = 'UTF8';
DROP SCHEMA IF EXISTS core CASCADE;
BEGIN;

CREATE SCHEMA core;
SET search_path = core;

CREATE TABLE currencies (
	code character(3) NOT NULL primary key,
	name text
);

CREATE TABLE currency_rates (
	code character(3) NOT NULL REFERENCES currencies(code),
	day date not null default CURRENT_DATE,
	rate numeric,
	PRIMARY KEY (code, day)
);

COMMIT;

CREATE OR REPLACE FUNCTION gen_random_bytes(integer) RETURNS bytea AS '$libdir/pgcrypto', 'pg_random_bytes' LANGUAGE c STRICT;


-- used by other functions, below, for any random strings needed
CREATE OR REPLACE FUNCTION random_string(length integer) RETURNS text AS $$
DECLARE
	chars text[] := '{0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z}';
	result text := '';
	i integer := 0;
	rand bytea;
BEGIN
	-- Generate secure random bytes and convert them to a string of chars.
	-- Since our charset contains 62 characters, we will have a small
	-- modulo bias, which is acceptable for our uses.
	rand := core.gen_random_bytes(length);
	FOR i IN 0..length-1 LOOP
		result := result || chars[1 + (get_byte(rand, i) % array_length(chars, 1))];
		-- note: rand indexing is zero-based, chars is 1-based.
	END LOOP;
	RETURN result;
END;
$$ LANGUAGE plpgsql;


-- ensure unique unused value for any table.field.
CREATE OR REPLACE FUNCTION unique_for_table_field(str_len integer, table_name text, field_name text) RETURNS text AS $$
DECLARE
	nu text;
	rowcount integer;
BEGIN
	nu := core.random_string(str_len);
	LOOP
		EXECUTE 'SELECT 1 FROM ' || table_name || ' WHERE ' || field_name || ' = ' || quote_literal(nu);
		GET DIAGNOSTICS rowcount = ROW_COUNT;
		IF rowcount = 0 THEN
			RETURN nu; 
		END IF;
		nu := core.random_string(str_len);
	END LOOP;
END;
$$ LANGUAGE plpgsql;


-- For updating foreign keys, tables referencing this column
-- tablename in schema.table format like 'woodegg.researchers' colname: 'person_id'
-- PARAMS: schema, table, column
CREATE OR REPLACE FUNCTION tables_referencing(text, text, text)
	RETURNS TABLE(tablename text, colname name) AS $$
BEGIN
	RETURN QUERY SELECT CONCAT(n.nspname, '.', k.relname), a.attname
		FROM pg_constraint c
		INNER JOIN pg_class k ON c.conrelid = k.oid
		INNER JOIN pg_attribute a ON c.conrelid = a.attrelid
		INNER JOIN pg_namespace n ON k.relnamespace = n.oid
		WHERE c.confrelid = (SELECT oid FROM pg_class WHERE relname = $2 
			AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = $1))
		AND ARRAY[a.attnum] <@ c.conkey
		AND c.confkey @> (SELECT array_agg(attnum) FROM pg_attribute
			WHERE attname = $3 AND attrelid = c.confrelid);
END;
$$ LANGUAGE plpgsql;


-- RETURNS: array of column names that ARE allowed to be updated
-- PARAMS: schema name, table name, array of col names NOT allowed to be updated
CREATE OR REPLACE FUNCTION cols2update(text, text, text[]) RETURNS text[] AS $$
BEGIN
	RETURN array(SELECT column_name::text FROM information_schema.columns
		WHERE table_schema=$1 AND table_name=$2 AND column_name != ALL($3));
END;
$$ LANGUAGE plpgsql;


-- PARAMS: table name, id, json, array of cols that ARE allowed to be updated
CREATE OR REPLACE FUNCTION jsonupdate(text, integer, json, text[]) RETURNS VOID AS $$
DECLARE
	col record;
BEGIN
	FOR col IN SELECT name FROM json_object_keys($3) AS name LOOP
		CONTINUE WHEN col.name != ALL($4);
		EXECUTE format ('UPDATE %s SET %I =
			(SELECT %I FROM json_populate_record(null::%s, $1)) WHERE id = %L',
			$1, col.name, col.name, $1, $2) USING $3;
	END LOOP;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: any text that needs to be stripped of HTML tags
CREATE OR REPLACE FUNCTION strip_tags(text) RETURNS text AS $$
BEGIN
	RETURN regexp_replace($1 , '</?[^>]+?>', '', 'g');
END;
$$ LANGUAGE plpgsql;


-- PARAMS: any text that needs HTML escape
CREATE OR REPLACE FUNCTION escape_html(text) RETURNS text AS $$
DECLARE
	nu text;
BEGIN
	nu := replace($1, '&', '&amp;');
	nu := replace(nu, '''', '&#39;');
	nu := replace(nu, '"', '&quot;');
	nu := replace(nu, '<', '&lt;');
	nu := replace(nu, '>', '&gt;');
	RETURN nu;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: JSON of currency rates https://openexchangerates.org/documentation
CREATE OR REPLACE FUNCTION update_currency_rates(jsonb) RETURNS void AS $$
DECLARE
	rates jsonb;
	acurrency currencies;
	acode text;
	arate numeric;
BEGIN
	rates := jsonb_extract_path($1, 'rates');
	FOR acurrency IN SELECT * FROM core.currencies LOOP
		acode := acurrency.code;
		arate := CAST((rates ->> acode) AS numeric);
		INSERT INTO core.currency_rates (code, rate) VALUES (acode, arate);
	END LOOP;
	RETURN;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: amount, from.code to.code
CREATE OR REPLACE FUNCTION currency_from_to(numeric, text, text, OUT amount numeric) AS $$
BEGIN
	IF $2 = 'USD' THEN
		SELECT ($1 * rate) INTO amount
			FROM core.currency_rates WHERE code = $3
			ORDER BY day DESC LIMIT 1;
	ELSIF $3 = 'USD' THEN
		SELECT ($1 / rate) INTO amount
			FROM core.currency_rates WHERE code = $2
			ORDER BY day DESC LIMIT 1;
	ELSE
		SELECT (
			(SELECT $1 / rate
				FROM core.currency_rates WHERE code = $2
				ORDER BY day DESC LIMIT 1) * rate) INTO amount
			FROM core.currency_rates WHERE code = $3
			ORDER BY day DESC LIMIT 1;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- GET /currencies
-- PARAMS: -none-
-- RETURNS array of objects:
-- [{"code":"AUD","name":"Australian Dollar"},{"code":"BGN","name":"Bulgarian Lev"}... ]
CREATE OR REPLACE FUNCTION all_currencies(
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := json_agg(r) FROM (SELECT * FROM core.currencies ORDER BY code) r;
END;
$$ LANGUAGE plpgsql;


-- GET /currency_names
-- PARAMS: -none-
-- RETURNS single code:name object:
-- {"AUD":"Australian Dollar", "BGN":"Bulgarian Lev", ...}
CREATE OR REPLACE FUNCTION currency_names(
	OUT mime text, OUT js json) AS $$
BEGIN
	mime := 'application/json';
	js := json_object(
		ARRAY(SELECT code FROM core.currencies ORDER BY code),
		ARRAY(SELECT name FROM core.currencies ORDER BY code));
END;
$$ LANGUAGE plpgsql;



