-- strip all line breaks, tabs, and spaces around thought before storing
CREATE OR REPLACE FUNCTION lat.clean_pairing() RETURNS TRIGGER AS $$
BEGIN
	NEW.thoughts = btrim(regexp_replace(NEW.thoughts, '\s+', ' ', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_pairing ON lat.pairings CASCADE;
CREATE TRIGGER clean_pairing BEFORE INSERT OR UPDATE OF thoughts ON lat.pairings
	FOR EACH ROW EXECUTE PROCEDURE lat.clean_pairing();
