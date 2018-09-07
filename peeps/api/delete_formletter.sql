--Route{
--  api = "peeps.delete_formletter",
--  args = {"id"},
--  method = "DELETE",
--  url = "/formletters/([0-9]+)",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_formletter(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.formletter_view r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; RETURN; END IF;
	DELETE FROM peeps.formletters WHERE id = $1;
END;
$$ LANGUAGE plpgsql;
