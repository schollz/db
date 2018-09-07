-- Setting a URL to be the "main" one sets all other URLs for that person to be NOT main
CREATE OR REPLACE FUNCTION peeps.one_main_url() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.main = 't' THEN
		UPDATE peeps.urls SET main=FALSE WHERE person_id=NEW.person_id AND id != NEW.id;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS one_main_url ON peeps.urls CASCADE;
CREATE TRIGGER one_main_url
	AFTER INSERT OR UPDATE OF main ON peeps.urls
	FOR EACH ROW EXECUTE PROCEDURE peeps.one_main_url();
