-- strip all line breaks, tabs, and spaces around url before storing (& validating)
CREATE OR REPLACE FUNCTION lat.clean_url() RETURNS TRIGGER AS $$
BEGIN
	NEW.url = regexp_replace(NEW.url, '\s', '', 'g');
	NEW.notes = btrim(regexp_replace(NEW.notes, '\s+', ' ', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_url ON lat.urls CASCADE;
CREATE TRIGGER clean_url BEFORE INSERT OR UPDATE ON lat.urls
	FOR EACH ROW EXECUTE PROCEDURE lat.clean_url();
