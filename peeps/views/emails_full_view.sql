DROP VIEW IF EXISTS peeps.emails_full_view CASCADE;
CREATE VIEW peeps.emails_full_view AS
	SELECT id,
	message_id,
	profile,
	category,
	created_at,
	opened_at,
	closed_at,
	their_email,
	their_name,
	subject,
	headers,
	body,
	outgoing,
	person_id
	FROM peeps.emails;
