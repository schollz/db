-- Strip all line breaks and spaces around translation before storing
CREATE OR REPLACE FUNCTION words.clean_xion() RETURNS TRIGGER AS $$
BEGIN
	NEW.translation = btrim(regexp_replace(NEW.translation, '\s+', ' ', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_xion ON words.translations CASCADE;
CREATE TRIGGER clean_xion
	BEFORE INSERT OR UPDATE OF translation ON words.translations
	FOR EACH ROW EXECUTE PROCEDURE words.clean_xion();
