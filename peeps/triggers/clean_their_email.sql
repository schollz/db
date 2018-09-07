CREATE OR REPLACE FUNCTION peeps.clean_their_email() RETURNS TRIGGER AS $$
BEGIN
	NEW.their_name = core.strip_tags(btrim(regexp_replace(NEW.their_name, '\s+', ' ', 'g')));
	NEW.their_email = lower(regexp_replace(NEW.their_email, '\s', '', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_their_email ON peeps.emails CASCADE;
CREATE TRIGGER clean_their_email
	BEFORE INSERT OR UPDATE OF their_name, their_email ON peeps.emails
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_their_email();
