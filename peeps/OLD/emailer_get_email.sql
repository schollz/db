-- Returns emails.* only if emailers.profiles && emailers.cateories matches
CREATE OR REPLACE FUNCTION peeps.emailer_get_email(emailer_id integer, email_id integer) RETURNS SETOF peeps.emails AS $$
DECLARE
	emailer peeps.emailers;
	email peeps.emails;
BEGIN
	RETURN QUERY SELECT * FROM peeps.emails WHERE id = email_id;
--	SELECT * INTO emailer FROM peeps.emailers WHERE id = emailer_id;
--	SELECT * INTO email FROM peeps.emails WHERE id = email_id;
--	IF (emailer.profiles = '{ALL}' AND emailer.categories = '{ALL}') OR
--	   (emailer.profiles = '{ALL}' AND email.category = ANY(emailer.categories)) OR
--	   (email.profile = ANY(emailer.profiles) AND emailer.categories = '{ALL}') OR
--	   (email.profile = ANY(emailer.profiles) AND email.category = ANY(emailer.categories)) THEN
--	END IF;
END;
$$ LANGUAGE plpgsql;
