-- ids of already-open emails
-- PARAMS: emailer_id (MOOT)
CREATE OR REPLACE FUNCTION peeps.opened_email_ids(integer) RETURNS SETOF integer AS $$
	SELECT id
	FROM peeps.emails
	WHERE opened_by IS NOT NULL
	AND closed_at IS NULL
	ORDER BY id;
$$ LANGUAGE sql;
