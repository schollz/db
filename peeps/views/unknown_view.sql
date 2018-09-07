DROP VIEW IF EXISTS peeps.unknown_view CASCADE;
CREATE VIEW peeps.unknown_view AS
	SELECT id,
	their_email,
	their_name,
	headers,
	subject,
	body
	FROM peeps.emails;
