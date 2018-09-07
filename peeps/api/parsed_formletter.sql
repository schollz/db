-- response is a simple JSON object: {"body": "The parsed text here, Derek."}
-- If wrong IDs given, value is null
--Route{
--  api = "peeps.parsed_formletter",
--  args = {"person_id", "formletter_id"},
--  method = "GET",
--  url = "/parsed_fomletter/([0-9]+)/([0-9]+)",
--  captures = {"person_id", "formletter_id"},
--}
CREATE OR REPLACE FUNCTION peeps.parsed_formletter(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_build_object('body', parse_formletter_body($1, $2));
	status := 200;
END;
$$ LANGUAGE plpgsql;
