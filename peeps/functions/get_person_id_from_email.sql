-- PARAMS: email
-- RETURNS: peeps.people.id or NULL
CREATE OR REPLACE FUNCTION peeps.get_person_id_from_email(text, OUT id integer) AS $$
DECLARE
	clean_email text;
BEGIN
	id := NULL;
	-- return immediately if email is null or badly formed
	IF $1 IS NULL THEN RETURN; END IF;
	clean_email := lower(regexp_replace($1, '\s', '', 'g'));
	IF clean_email !~ '\A\S+@\S+\.\S+\Z' THEN RETURN; END IF;
	SELECT p.id INTO id
	FROM peeps.people p
	WHERE email = clean_email;
END;
$$ LANGUAGE plpgsql;
