--Route{
--  api = "peeps.get_person",
--  args = {"person_id"},
--  method = "GET",
--  url = "/person/([0-9]+)",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
