DROP VIEW IF EXISTS peeps.stats_view CASCADE;
CREATE VIEW peeps.stats_view AS
	SELECT stats.id,
	stats.created_at,
	statkey AS name,
	statvalue AS value, (
		SELECT row_to_json(p)
		FROM (
			SELECT people.id, people.name, people.email
		) p
	) AS person
	FROM peeps.stats
		INNER JOIN peeps.people
		ON stats.person_id=people.id
	ORDER BY stats.id DESC;
