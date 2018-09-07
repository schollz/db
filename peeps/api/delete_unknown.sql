--Route{
--  api = "peeps.delete_unknown",
--  args = {"emailer_id", "email_id"},
--  method = "DELETE",
--  url = "/unknowns/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_unknown(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.unknown_view r
	WHERE id IN (
		SELECT * FROM peeps.unknown_email_ids($1)
	) AND id = $2;
	IF js IS NULL THEN status := 404;
	js := '{}'; RETURN; END IF;
	status := 200;
	DELETE FROM peeps.emails WHERE id = $2;
END;
$$ LANGUAGE plpgsql;
