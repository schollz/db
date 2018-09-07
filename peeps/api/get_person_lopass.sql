--Route{
--  api = "peeps.get_person_lopass",
--  args = {"person_id", "lopass"},
--  method = "GET",
--  url = "/person/([0-9]+)/([a-zA-Z0-9]{4})",
--  captures = {"person_id", "lopass"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person_lopass(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid
	FROM peeps.people
	WHERE id = $1
	AND lopass = $2;
	IF pid IS NULL THEN status := 404;
	js := '{}'; RETURN; END IF;
	SELECT x.status, x.js INTO status, js FROM peeps.get_person($1) x;
END;
$$ LANGUAGE plpgsql;
