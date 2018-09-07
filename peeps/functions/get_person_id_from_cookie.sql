-- Give the cookie text, and I'll return person_id if found, NULL if not
CREATE OR REPLACE FUNCTION peeps.get_person_id_from_cookie(text, OUT person_id integer) AS $$
	SELECT person_id FROM peeps.logins WHERE cookie = $1;
$$ LANGUAGE sql;
