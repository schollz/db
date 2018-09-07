--Route{
-- api = "lat.get_url",
-- args = {"id"},
-- method = "GET",
-- url = "/urls/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION lat.get_url(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*)
		FROM lat.urls r
		WHERE id = $1;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
END;
$$ LANGUAGE plpgsql;

