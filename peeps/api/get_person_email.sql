--Route{
--  api = "peeps.get_person_email",
--  args = {"email"},
--  method = "GET",
--  url = "/person",
--  params = {"email"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person_email(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid
	FROM peeps.get_person_id_from_email($1);
	IF pid IS NULL THEN status := 404;
	js := '{}'; END IF;
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = pid;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
