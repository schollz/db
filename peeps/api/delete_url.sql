--Route{
--  api = "peeps.delete_url",
--  args = {"id"},
--  method = "DELETE",
--  url = "/urls/([0-9]+)",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_url(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.urls r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; RETURN; END IF;
	DELETE FROM peeps.urls WHERE id = $1;
END;
$$ LANGUAGE plpgsql;
