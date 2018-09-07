-- Update it to be shown as opened_by this emailer now (if not already open)
-- Returns email.id if newly opened, NULL if not
-- PARAMS: emailer_id, email_id
CREATE OR REPLACE FUNCTION peeps.open_email(integer, integer) RETURNS integer AS $$
	UPDATE peeps.emails
	SET opened_at = NOW(),
	opened_by = $1
	WHERE id = $2
	AND opened_by IS NULL
	RETURNING id;
$$ LANGUAGE sql;
