-- atkey lower a-z or -
CREATE OR REPLACE FUNCTION peeps.clean_atkey() RETURNS TRIGGER AS $$
BEGIN
	NEW.atkey = regexp_replace(lower(NEW.atkey), '[^a-z-]', '', 'g');
	IF NEW.atkey = '' THEN
		RAISE 'atkeys.atkey must not be empty';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_atkey ON peeps.atkey CASCADE;
CREATE TRIGGER clean_atkey
	BEFORE INSERT OR UPDATE OF atkey ON peeps.atkeys
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_atkey();
