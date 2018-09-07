--Route{
--  api = "peeps.close_email",
--  args = {"emailer_id", "email_id"},
--  method = "PUT",
--  url = "/email/([0-9]+)/([0-9]+)/close",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.close_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE peeps.emails
	SET closed_at = NOW(), closed_by = $1
	WHERE id = $2;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = $2;
	status := 200;
END;
$$ LANGUAGE plpgsql;
