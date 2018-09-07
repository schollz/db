CREATE OR REPLACE FUNCTION words.clean_template() RETURNS TRIGGER AS $$
BEGIN
	NEW.template = replace(NEW.template, E'\r', '');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_template ON words.articles CASCADE;
CREATE TRIGGER clean_template
	BEFORE INSERT OR UPDATE OF template ON words.articles
	FOR EACH ROW EXECUTE PROCEDURE words.clean_template();
