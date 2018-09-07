-- lowercase and strip all line breaks, tabs, and spaces around tag before storing
CREATE OR REPLACE FUNCTION lat.clean_tag() RETURNS TRIGGER AS $$
BEGIN
	NEW.tag = lower(btrim(regexp_replace(NEW.tag, '\s+', ' ', 'g')));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_tag ON lat.tags CASCADE;
CREATE TRIGGER clean_tag BEFORE INSERT OR UPDATE OF tag ON lat.tags
	FOR EACH ROW EXECUTE PROCEDURE lat.clean_tag();
