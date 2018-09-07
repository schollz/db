-- For signups where new user gives name, email, AND password at once.
-- Don't want to set password if email already exists in system, otherwise attacker
-- could use it to change someone's password. So check existence first, then create.
-- If email/person exists already, just return person. Don't change password.
-- PARAMS: name, email, password
CREATE OR REPLACE FUNCTION peeps.person_create_pass(text, text, text) RETURNS SETOF peeps.people AS $$
DECLARE
	clean_email text;
	pid integer;
BEGIN
	clean_email := lower(regexp_replace($2, '\s', '', 'g'));
	IF clean_email IS NULL OR clean_email = '' THEN
		RAISE 'missing_email';
	END IF;
	SELECT id INTO pid FROM peeps.people WHERE email = clean_email;
	IF pid IS NULL THEN
		SELECT id INTO pid FROM peeps.person_create($1, $2);
		PERFORM peeps.set_hashpass(pid, $3);
	END IF;
	RETURN QUERY SELECT * FROM peeps.people WHERE id = pid;
END;
$$ LANGUAGE plpgsql;
