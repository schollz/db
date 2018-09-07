-- PARAMS: email, password
CREATE OR REPLACE FUNCTION peeps.pid_from_email_pass(text, text, OUT pid integer) AS $$
DECLARE
	clean_email text;
BEGIN
	IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
		clean_email := lower(regexp_replace($1, '\s', '', 'g'));
		IF clean_email ~ '\A\S+@\S+\.\S+\Z' AND LENGTH($2) > 3 THEN
			SELECT id INTO pid
			FROM peeps.people
			WHERE email = clean_email
			AND hashpass = peeps.crypt($2, hashpass);
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;
