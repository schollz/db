-- Finds interest words in email body that are not yet in person's interests
--Route{
--  api = "peeps.interests_in_email",
--  args = {"id"},
--  method = "GET",
--  url = "/emails/([0-9]+)/interests",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.interests_in_email(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := to_json(ARRAY(
		SELECT inkey
		FROM peeps.inkeys
		WHERE inkey IN (
			SELECT regexp_split_to_table(lower(body), '[^a-z]+')
			FROM peeps.emails
			WHERE id = $1
		)
		AND inkey NOT IN (
			SELECT interest
			FROM peeps.interests
				JOIN peeps.emails
				ON peeps.emails.person_id = peeps.interests.person_id
			WHERE peeps.emails.id = $1
		)
	));
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
