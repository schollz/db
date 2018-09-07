DROP VIEW IF EXISTS peeps.emails_view CASCADE;
CREATE VIEW peeps.emails_view AS
	SELECT id,
	subject,
	created_at,
	their_name,
	their_email
	FROM peeps.emails;
