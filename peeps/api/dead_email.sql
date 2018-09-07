--Route{
--  api = "peeps.dead_email",
--  args = {"person_id"},
--  method = "PUT",
--  url = "/person/([0-9]+)/dead",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.dead_email(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE peeps.people
	SET
		email = NULL,
		listype = NULL,
		notes = CONCAT('DEAD EMAIL: ', email, E'\n', notes)
	WHERE id = $1
	AND email IS NOT NULL;
	IF NOT FOUND THEN
		status := 404;
		js := '{}';
		RETURN;
	END IF;
	status := 200;
	js := json_build_object('ok', $1);
END;
$$ LANGUAGE plpgsql;

--Route{
--  api = "peeps.dead_email",
--  args = {"email"},
--  method = "PUT",
--  url = "/person/dead?email=this@that",
--}
CREATE OR REPLACE FUNCTION peeps.dead_email(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid FROM peeps.get_person_id_from_email($1);
	IF pid IS NULL THEN
		status := 404;
		js := '{}';
		RETURN;
	END IF;
	SELECT x.status, x.js INTO status, js FROM peeps.dead_email(pid) x;
END;
$$ LANGUAGE plpgsql;

