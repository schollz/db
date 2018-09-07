--Route{
--  api = "peeps.sent_emails_grouped",
--  method = "GET",
--  url = "/emails/sent",
--}
CREATE OR REPLACE FUNCTION peeps.sent_emails_grouped(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT p.id, p.name, (
			SELECT json_agg(x) AS sent
			FROM (
				SELECT id, subject, created_at, their_name, their_email
				FROM peeps.emails
				WHERE closed_by = e.id
				AND outgoing IS TRUE
				AND closed_at > (NOW() - interval '9 days')
				ORDER BY id DESC
			) x
		)
		FROM peeps.emailers e, peeps.people p
		WHERE e.person_id = p.id
		AND e.id IN (
			SELECT DISTINCT(created_by)
			FROM peeps.emails
			WHERE closed_at > (NOW() - interval '9 days')
			AND outgoing IS TRUE
		)
		ORDER BY e.id DESC
	) r;
END;
$$ LANGUAGE plpgsql;
