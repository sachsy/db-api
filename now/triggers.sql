----------------------------
------------------ TRIGGERS:
----------------------------

-- everyone with a now.url will probably a public_id soon, so after 
-- insert of now.url, or update of person_id, create public_id if not there already
CREATE OR REPLACE FUNCTION now.ensure_public_id() RETURNS TRIGGER AS $$
BEGIN
	UPDATE peeps.people
		SET public_id=core.unique_for_table_field(4, 'peeps.people', 'public_id')
		WHERE id = NEW.person_id AND public_id IS NULL;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS ensure_public_id ON now.urls CASCADE;
CREATE TRIGGER ensure_public_id AFTER INSERT OR UPDATE OF person_id ON now.urls
	FOR EACH ROW EXECUTE PROCEDURE now.ensure_public_id();

