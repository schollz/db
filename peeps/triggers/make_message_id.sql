-- generate message_id for outgoing emails
CREATE OR REPLACE FUNCTION peeps.make_message_id() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.message_id IS NULL AND (NEW.outgoing IS TRUE OR NEW.outgoing IS NULL) THEN
		NEW.message_id = CONCAT(
			to_char(current_timestamp, 'YYYYMMDDHH24MISSMS'),
			'.', NEW.person_id, '@sivers.org');
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS make_message_id ON peeps.emails CASCADE;
CREATE TRIGGER make_message_id
	BEFORE INSERT ON peeps.emails
	FOR EACH ROW EXECUTE PROCEDURE peeps.make_message_id();
