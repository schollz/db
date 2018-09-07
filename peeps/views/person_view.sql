DROP VIEW IF EXISTS peeps.person_view CASCADE;
CREATE VIEW peeps.person_view AS
	SELECT id,
	name,
	address,
	email,
	company,
	city,
	state,
	country,
	notes,
	lopass,
	listype,
	categorize_as,
	created_at,
	checked_by,
	checked_at, (
		SELECT json_agg(s) AS stats
		FROM (
			SELECT id,
			created_at,
			statkey AS name,
			statvalue AS value
			FROM peeps.stats
			WHERE person_id = peeps.people.id
			ORDER BY id
		) s
	), (
		SELECT json_agg(u) AS urls
		FROM (
			SELECT id,
			url,
			main
			FROM peeps.urls
			WHERE person_id = peeps.people.id
			ORDER BY main DESC NULLS LAST, id
		) u
	), (
		SELECT json_agg(e) AS emails
		FROM (
			SELECT id,
			created_at,
			subject,
			outgoing FROM peeps.emails
			WHERE person_id = peeps.people.id
			ORDER BY id
		) e
	)
	FROM peeps.people;
