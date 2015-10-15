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


