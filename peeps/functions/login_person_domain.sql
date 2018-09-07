-- Once a person has correctly given their email and password, call this to create cookie info.
-- Returns a single string ready to be set as the cookie value. (Trigger creates it.)
-- PARAMS: person_id, domain.  
CREATE OR REPLACE FUNCTION peeps.login_person_domain(integer, text, OUT cookie text) AS $$
BEGIN
	SELECT peeps.logins.cookie INTO cookie
	FROM peeps.logins
	WHERE person_id = $1
	AND domain = $2;
	IF NOT FOUND THEN
		INSERT INTO peeps.logins(person_id, domain)
		VALUES ($1, $2)
		RETURNING peeps.logins.cookie INTO cookie;
	END IF;
END;
$$ LANGUAGE plpgsql;
