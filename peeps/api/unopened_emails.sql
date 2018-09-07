--Route{
--  api = "peeps.unopened_emails",
--  args = {"emailer_id", "profile", "category"},
--  method = "GET",
--  url = "/unopened/([0-9]+)/([a-z@]+)/([a-zA-Z@.-]+)",
--  captures = {"emailer_id", "profile", "category"},
--}
CREATE OR REPLACE FUNCTION peeps.unopened_emails(integer, text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.emails_view
		WHERE id IN (
			SELECT id
			FROM peeps.emails
			WHERE id IN (
				SELECT * FROM peeps.unopened_email_ids($1)
			)
			AND profile = $2
			AND category = $3
		) ORDER BY id
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
