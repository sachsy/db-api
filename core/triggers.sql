---------------------
------------ TRIGGERS
---------------------

CREATE OR REPLACE FUNCTION clean_raw() RETURNS TRIGGER AS $$
BEGIN
	NEW.raw = replace(NEW.raw, E'\r', '');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_raw ON translation_files CASCADE;
CREATE TRIGGER clean_raw
	BEFORE INSERT OR UPDATE OF raw ON translation_files
	FOR EACH ROW EXECUTE PROCEDURE clean_raw();


CREATE FUNCTION translations_code_gen() RETURNS TRIGGER AS $$
BEGIN
	NEW.code = core.unique_for_table_field(8, 'core.translations', 'code');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER translations_code_gen
	BEFORE INSERT ON translations
	FOR EACH ROW WHEN (NEW.code IS NULL)
	EXECUTE PROCEDURE translations_code_gen();


