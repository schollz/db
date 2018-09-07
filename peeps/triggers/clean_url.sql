-- urls.url remove all whitespace, then add http:// if not there
CREATE OR REPLACE FUNCTION peeps.clean_url() RETURNS TRIGGER AS $$
BEGIN
	NEW.url = regexp_replace(NEW.url, '\s', '', 'g');
	IF NEW.url !~ '^https?://' THEN
		NEW.url = 'http://' || NEW.url;
	END IF;
	IF NEW.url !~ '^https?://[0-9a-zA-Z_-]+\.[a-zA-Z0-9]+' THEN
		RAISE 'bad url';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_url ON peeps.urls CASCADE;
CREATE TRIGGER clean_url
	BEFORE INSERT OR UPDATE OF url ON peeps.urls
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_url();
