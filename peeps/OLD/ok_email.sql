-- If this emailer is allowed to see this email,
-- Returns email.id if found and permission granted, NULL if not
-- PARAMS: emailer_id, email_id
CREATE OR REPLACE FUNCTION peeps.ok_email(integer, integer) RETURNS integer AS $$
DECLARE
	pros text[];
	cats text[];
	eid integer;
BEGIN
	SELECT profiles, categories INTO pros, cats FROM peeps.emailers WHERE id = $1;
	IF pros = array['ALL'] AND cats = array['ALL'] THEN
		SELECT id INTO eid FROM peeps.emails WHERE id = $2;
	ELSIF cats = array['ALL'] THEN
		SELECT id INTO eid FROM peeps.emails WHERE id = $2 AND profile = ANY(pros);
	ELSIF pros = array['ALL'] THEN
		SELECT id INTO eid FROM peeps.emails WHERE id = $2 AND category = ANY(cats);
	ELSE
		SELECT id INTO eid FROM peeps.emails WHERE id = $2
			AND profile = ANY(pros) AND category = ANY(cats);
	END IF;
	RETURN eid;
END;
$$ LANGUAGE plpgsql;
