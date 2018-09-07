-- strip all line breaks, tabs, and spaces around title and concept before storing
CREATE OR REPLACE FUNCTION lat.clean_concept() RETURNS TRIGGER AS $$
BEGIN
	NEW.title = btrim(regexp_replace(NEW.title, '\s+', ' ', 'g'));
	NEW.concept = btrim(regexp_replace(NEW.concept, '\s+', ' ', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_concept ON lat.concepts CASCADE;
CREATE TRIGGER clean_concept BEFORE INSERT OR UPDATE ON lat.concepts
	FOR EACH ROW EXECUTE PROCEDURE lat.clean_concept();

