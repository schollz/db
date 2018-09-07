-- No whitespace, all lowercase, for emails.profile and emails.category
CREATE OR REPLACE FUNCTION peeps.clean_emails_fields() RETURNS TRIGGER AS $$
BEGIN
	NEW.profile = regexp_replace(lower(NEW.profile), '[^[:alnum:]_@-]', '', 'g');
	IF TG_OP = 'INSERT' AND (NEW.category IS NULL OR trim(both ' ' from NEW.category) = '') THEN
		NEW.category = NEW.profile;
	ELSE
		NEW.category = regexp_replace(lower(NEW.category), '[^[:alnum:]_@-]', '', 'g');
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_emails_fields ON peeps.emails CASCADE;
CREATE TRIGGER clean_emails_fields
	BEFORE INSERT OR UPDATE OF profile, category ON peeps.emails
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_emails_fields();
