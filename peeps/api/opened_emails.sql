--Route{
--  api = "peeps.opened_emails",
--  args = {"emailer_id"},
--  method = "GET",
--  url = "/opened/([0-9]+)",
--  captures = {"emailer_id"},
--}
CREATE OR REPLACE FUNCTION peeps.opened_emails(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT e.id,
			subject,
			opened_at,
			p.name
		FROM peeps.emails e
			JOIN peeps.emailers r ON e.opened_by=r.id
			JOIN peeps.people p ON r.person_id=p.id
		WHERE e.id IN (
			SELECT * FROM peeps.opened_email_ids($1)
		)
		ORDER BY opened_at
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
