--Route{
--  api = "peeps.unread_email",
--  args = {"emailer_id", "email_id"},
--  method = "PUT",
--  url = "/email/([0-9]+)/([0-9]+)/unread",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.unread_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE peeps.emails
	SET opened_at=NULL, opened_by=NULL, closed_at=NULL, closed_by=NULL
	WHERE id = $2;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = $2;
	status := 200;
END;
$$ LANGUAGE plpgsql;
