--Route{
--  api = "peeps.get_email",
--  args = {"emailer_id", "email_id"},
--  method = "POST",
--  url = "/email/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
BEGIN
	PERFORM * FROM peeps.open_email($1, $2);
	status := 200;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = $2;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;
