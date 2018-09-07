-- Update people.email_count when number of emails for this person_id changes
CREATE OR REPLACE FUNCTION peeps.update_email_count() RETURNS TRIGGER AS $$
DECLARE
	pid integer := NULL;
BEGIN
	IF ((TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.person_id IS NOT NULL) THEN
		pid := NEW.person_id;
	ELSIF (TG_OP = 'UPDATE' AND OLD.person_id IS NOT NULL) THEN
		pid := OLD.person_id;  -- in case updating to set person_id = NULL, recalcuate old one
	ELSIF (TG_OP = 'DELETE' AND OLD.person_id IS NOT NULL) THEN
		pid := OLD.person_id;
	END IF;
	IF pid IS NOT NULL THEN
		UPDATE peeps.people SET email_count=
			(SELECT COUNT(*) FROM peeps.emails WHERE person_id = pid AND outgoing IS FALSE)
			WHERE id = pid;
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS update_email_count ON peeps.emails CASCADE;
CREATE TRIGGER update_email_count
	AFTER INSERT OR DELETE OR UPDATE OF person_id ON peeps.emails
	FOR EACH ROW EXECUTE PROCEDURE peeps.update_email_count();
