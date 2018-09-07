CREATE OR REPLACE FUNCTION peeps.generated_login_fields() RETURNS TRIGGER AS $$
BEGIN
	IF NEW.cookie IS NULL THEN
		NEW.cookie = core.random_string(32);
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS generate_login_fields ON peeps.people CASCADE;
CREATE TRIGGER generate_login_fields
	BEFORE INSERT ON peeps.logins
	FOR EACH ROW EXECUTE PROCEDURE peeps.generated_login_fields();
