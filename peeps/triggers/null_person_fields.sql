-- If something sets any of these fields to '', change it to NULL before saving
CREATE OR REPLACE FUNCTION peeps.null_person_fields() RETURNS TRIGGER AS $$
BEGIN
	IF btrim(NEW.country) = '' THEN
		NEW.country = NULL;
	END IF;
	IF btrim(NEW.email) = '' THEN
		NEW.email = NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS null_person_fields ON peeps.people CASCADE;
CREATE TRIGGER null_person_fields
	BEFORE INSERT OR UPDATE OF country, email ON peeps.people
	FOR EACH ROW EXECUTE PROCEDURE peeps.null_person_fields();
