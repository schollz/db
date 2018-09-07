--Route{
--  api = "peeps.delete_email",
--  args = {"emailer_id", "email_id"},
--  method = "DELETE",
--  url = "/email/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.delete_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = $2;
	status := 200;
	DELETE FROM peeps.emails WHERE id = $2;
END;
$$ LANGUAGE plpgsql;
