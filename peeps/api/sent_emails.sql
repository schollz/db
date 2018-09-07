--Route{
--  api = "peeps.sent_emails",
--  args = {"howmany"},
--  method = "GET",
--  url = "/emails/sent/([0-9]+)",
--  captures = {"howmany"},
--}
CREATE OR REPLACE FUNCTION peeps.sent_emails(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.emails_view
		WHERE id IN (
			SELECT id
			FROM peeps.emails
			WHERE outgoing IS TRUE
			ORDER BY id DESC
			LIMIT $1
		)
		ORDER BY id DESC
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;
