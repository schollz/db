-- Use this when a user is logging in with their email and (their own chosen) password.
-- USAGE: SELECT * FROM person_email_pass('dude@abid.es', 'Th€IR öld FunK¥ pá$$werđ');
-- Returns peeps.people.* if both are correct, or nothing if not.
-- Once authorized here, give login cookie for future lookups.
CREATE OR REPLACE FUNCTION peeps.person_email_pass(my_email text, my_pass text) RETURNS SETOF peeps.people AS $$
DECLARE
	clean_email text;
BEGIN
	clean_email := lower(regexp_replace(my_email, '\s', '', 'g'));
	IF clean_email !~ '\A\S+@\S+\.\S+\Z' THEN
		RAISE 'bad_email';
	END IF;
	IF my_pass IS NULL OR length(btrim(my_pass)) < 4 THEN
		RAISE 'short_password';
	END IF;
	RETURN QUERY SELECT * FROM peeps.people WHERE email=clean_email AND hashpass=peeps.crypt(my_pass, hashpass);
END;
$$ LANGUAGE plpgsql;
