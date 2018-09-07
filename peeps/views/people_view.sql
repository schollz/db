DROP VIEW IF EXISTS peeps.people_view CASCADE;
CREATE VIEW peeps.people_view AS
	SELECT id,
	name,
	email,
	email_count
	FROM peeps.people;
