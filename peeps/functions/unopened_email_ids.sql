-- ids of unopened emails 
-- PARAMS: emailer_id : MOOT
CREATE OR REPLACE FUNCTION peeps.unopened_email_ids(integer) RETURNS SETOF integer AS $$
	SELECT id
	FROM peeps.emails
	WHERE opened_by IS NULL
	AND person_id IS NOT NULL
	ORDER BY id;
$$ LANGUAGE sql;
