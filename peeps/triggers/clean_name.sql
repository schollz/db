-- Strip all line breaks and spaces around name before storing
CREATE OR REPLACE FUNCTION peeps.clean_name() RETURNS TRIGGER AS $$
BEGIN
	NEW.name = core.strip_tags(btrim(regexp_replace(NEW.name, '\s+', ' ', 'g')));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_name ON peeps.people CASCADE;
CREATE TRIGGER clean_name
	BEFORE INSERT OR UPDATE OF name ON peeps.people
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_name();
