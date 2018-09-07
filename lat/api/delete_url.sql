--Route{
-- api = "lat.delete_url",
-- args = {"id"},
-- method = "DELETE",
-- url = "/urls/([0-9]+)",
-- captures = {"id"},
--}
CREATE OR REPLACE FUNCTION lat.delete_url(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js FROM lat.get_url($1) x;
	DELETE FROM lat.urls WHERE id = $1;
END;
$$ LANGUAGE plpgsql;
