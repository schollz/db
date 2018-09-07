CREATE OR REPLACE FUNCTION earmouth.clean_user() RETURNS TRIGGER AS $$
BEGIN
	NEW.public_name = btrim(regexp_replace(NEW.public_name, '\s+', ' ', 'g'));
	NEW.bio = btrim(regexp_replace(NEW.bio, '\s+', ' ', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_user ON earmouth.users CASCADE;
CREATE TRIGGER clean_user
	BEFORE INSERT OR UPDATE OF public_name, bio ON earmouth.users
	FOR EACH ROW EXECUTE PROCEDURE earmouth.clean_user();

