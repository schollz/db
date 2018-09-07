-- Strip spaces and lowercase email address before validating & storing
CREATE OR REPLACE FUNCTION peeps.clean_email() RETURNS TRIGGER AS $$
BEGIN
	NEW.email = lower(regexp_replace(NEW.email, '\s', '', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_email ON peeps.people CASCADE;
CREATE TRIGGER clean_email
	BEFORE INSERT OR UPDATE OF email ON peeps.people
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_email();
