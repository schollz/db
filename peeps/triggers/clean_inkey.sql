-- inkey lower a-z or -
CREATE OR REPLACE FUNCTION peeps.clean_inkey() RETURNS TRIGGER AS $$
BEGIN
	NEW.inkey = regexp_replace(lower(NEW.inkey), '[^a-z-]', '', 'g');
	IF NEW.inkey = '' THEN
		RAISE 'inkeys.inkey must not be empty';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_inkey ON peeps.inkey CASCADE;
CREATE TRIGGER clean_inkey
	BEFORE INSERT OR UPDATE OF inkey ON peeps.inkeys
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_inkey();
