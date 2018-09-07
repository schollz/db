--Route{
-- api = "lat.get_pairing",
-- args = {"id"},
-- method = "GET",
-- url = "/pairings/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION lat.get_pairing(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r.*)
		FROM lat.pairing_view r
		WHERE id = $1;
	IF js IS NULL THEN 
	status := 404;
	js := '{}';
 END IF;
END;
$$ LANGUAGE plpgsql;
