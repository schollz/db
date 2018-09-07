--Route{
-- api = "lat.delete_pairing",
-- args = {"id"},
-- method = "DELETE",
-- url = "/pairings/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION lat.delete_pairing(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js FROM lat.get_pairing($1) x;
	DELETE FROM lat.pairings WHERE id = $1;
END;
$$ LANGUAGE plpgsql;
