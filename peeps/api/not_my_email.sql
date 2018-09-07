--Route{
--  api = "peeps.not_my_email",
--  args = {"emailer_id", "email_id"},
--  method = "PUT",
--  url = "/email/([0-9]+)/([0-9]+)/punt",
--  captures = {"emailer_id", "email_id"},
--}
CREATE OR REPLACE FUNCTION peeps.not_my_email(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE peeps.emails
	SET opened_at=NULL, opened_by=NULL, closed_at=NULL, closed_by=NULL,
	category=(
		SELECT substring(
			concat('not-', split_part(people.email,'@',1))
			from 1 for 8)
		FROM peeps.emailers
			JOIN peeps.people ON emailers.person_id=people.id
		WHERE emailers.id = $1
	)
	WHERE id = $2;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = $2;
	status := 200;
END;
$$ LANGUAGE plpgsql;
