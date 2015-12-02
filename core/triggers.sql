---------------------
------------ TRIGGERS
---------------------

CREATE OR REPLACE FUNCTION core.clean_raw() RETURNS TRIGGER AS $$
BEGIN
	NEW.raw = replace(NEW.raw, E'\r', '');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_raw ON core.translation_files CASCADE;
CREATE TRIGGER clean_raw
	BEFORE INSERT OR UPDATE OF raw ON core.translation_files
	FOR EACH ROW EXECUTE PROCEDURE core.clean_raw();


CREATE OR REPLACE FUNCTION core.translations_code_gen() RETURNS TRIGGER AS $$
BEGIN
	NEW.code = core.unique_for_table_field(8, 'core.translations', 'code');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS translations_code_gen ON core.translations CASCADE;
CREATE TRIGGER translations_code_gen
	BEFORE INSERT ON core.translations
	FOR EACH ROW WHEN (NEW.code IS NULL)
	EXECUTE PROCEDURE core.translations_code_gen();


CREATE OR REPLACE FUNCTION core.changelog_nodupe() RETURNS TRIGGER AS $$
DECLARE
	cid integer;
BEGIN
	SELECT id INTO cid FROM core.changelog
		WHERE person_id=NEW.person_id
		AND schema_name=NEW.schema_name
		AND table_name=NEW.table_name
		AND table_id=NEW.table_id
		AND approved IS NOT TRUE LIMIT 1;
	IF cid IS NULL THEN
		RETURN NEW;
	ELSE
		RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS changelog_nodupe ON core.changelog CASCADE;
CREATE TRIGGER changelog_nodupe
	BEFORE INSERT ON core.changelog
	FOR EACH ROW EXECUTE PROCEDURE core.changelog_nodupe();

