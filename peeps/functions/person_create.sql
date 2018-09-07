-- Use this to add a new person to the database.  Ensures unique email without clash.
-- USAGE: SELECT * FROM person_create('Dude Abides', 'dude@abid.es');
-- Will always return peeps.people row, whether new INSERT or existing SELECT
CREATE OR REPLACE FUNCTION peeps.person_create(new_name text, new_email text) RETURNS SETOF peeps.people AS $$
DECLARE
	clean_email text;
BEGIN
	clean_email := lower(regexp_replace(new_email, '\s', '', 'g'));
	IF clean_email IS NULL OR clean_email !~ '\A\S+@\S+\.\S+\Z' THEN
		RAISE 'missing_email';
	END IF;
	IF NOT EXISTS (SELECT 1 FROM peeps.people WHERE email = clean_email) THEN
		RETURN QUERY INSERT INTO peeps.people (name, email) VALUES (new_name, clean_email) RETURNING peeps.people.*;
	ELSE
		RETURN QUERY SELECT * FROM peeps.people WHERE email = clean_email;
	END IF;
END;
$$ LANGUAGE plpgsql;
