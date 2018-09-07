--Route{
--  api = "peeps.queued_emails",
--  method = "GET",
--  url = "/emails/queued",
--}
CREATE OR REPLACE FUNCTION peeps.queued_emails(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT e.id,
		e.profile,
		e.their_email,
		e.subject,
		e.body,
		e.message_id,
		ref.message_id AS referencing,
		peeps.quoted(ref.body) AS reftext
		FROM peeps.emails e
			LEFT JOIN peeps.emails ref ON e.reference_id = ref.id
		WHERE e.outgoing IS NULL
		ORDER BY e.id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
