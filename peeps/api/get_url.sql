--Route{
--  api = "peeps.get_url",
--  args = {"id"},
--  method = "GET",
--  url = "/urls/([0-9]+)",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_url(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.urls r WHERE id=$1;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
