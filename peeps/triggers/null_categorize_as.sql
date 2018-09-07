-- categorize_as can't be empty string. make it NULL if empty
CREATE OR REPLACE FUNCTION peeps.null_categorize_as() RETURNS TRIGGER AS $$
BEGIN
	NEW.categorize_as = lower(regexp_replace(NEW.categorize_as, '\s', '', 'g'));
	IF NEW.categorize_as = '' THEN
		NEW.categorize_as = NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS null_categorize_as ON peeps.people CASCADE;
CREATE TRIGGER null_categorize_as
	BEFORE INSERT OR UPDATE ON peeps.people
	FOR EACH ROW EXECUTE PROCEDURE peeps.null_categorize_as();
