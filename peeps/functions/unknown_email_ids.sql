-- ids of unknown-person emails
-- PARAMS: emailer_id : MOOT
CREATE OR REPLACE FUNCTION peeps.unknown_email_ids(integer) RETURNS SETOF integer AS $$
	SELECT id
	FROM peeps.emails
	WHERE person_id IS NULL
	ORDER BY id;
$$ LANGUAGE sql;
