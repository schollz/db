-- If formletters.accesskey is '', change it to NULL before saving
CREATE OR REPLACE FUNCTION peeps.null_accesskey() RETURNS TRIGGER AS $$
BEGIN
	IF btrim(NEW.accesskey) = '' THEN
		NEW.accesskey = NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS null_accesskey ON peeps.people CASCADE;
CREATE TRIGGER null_accesskey
	BEFORE INSERT OR UPDATE OF accesskey ON peeps.formletters
	FOR EACH ROW EXECUTE PROCEDURE peeps.null_accesskey();
