--Route{
-- api = "lat.delete_concept",
-- args = {"id"},
-- method = "DELETE",
-- url = "/concepts/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION lat.delete_concept(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js FROM lat.get_concept($1) x;
	DELETE FROM lat.concepts WHERE id = $1;
END;
$$ LANGUAGE plpgsql;
