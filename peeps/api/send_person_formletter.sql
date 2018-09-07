--Route{
--  api = "peeps.send_person_formletter",
--  args = {"person_id", "formletter_id", "profile"},
--  method = "POST",
--  url = "/send_fomletter/([0-9]+)/([0-9]+)/([a-z@]+)",
--  captures = {"person_id", "formletter_id", "profile"},
--}
CREATE OR REPLACE FUNCTION peeps.send_person_formletter(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
BEGIN
	-- outgoing_email params: emailer_id (2=robot), person_id, profile, category,
	-- subject, body, reference_id
	SELECT outgoing_email INTO email_id
	FROM peeps.outgoing_email(2, $1, $3, $3,
		(SELECT subject FROM peeps.parse_formletter_subject($1, $2)),
		(SELECT body FROM peeps.parse_formletter_body($1, $2)),
		NULL);
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = email_id;
	status := 200;
END;
$$ LANGUAGE plpgsql;
