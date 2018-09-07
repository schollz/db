CREATE OR REPLACE FUNCTION words.clean_raw() RETURNS TRIGGER AS $$
BEGIN
	NEW.raw = replace(NEW.raw, E'\r', '');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_raw ON words.articles CASCADE;
CREATE TRIGGER clean_raw
	BEFORE INSERT OR UPDATE OF raw ON words.articles
	FOR EACH ROW EXECUTE PROCEDURE words.clean_raw();
