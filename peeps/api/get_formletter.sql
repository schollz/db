--Route{
--  api = "peeps.get_formletter",
--  args = {"id"},
--  method = "GET",
--  url = "/formletters/([0-9]+)",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_formletter(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.formletter_view r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
