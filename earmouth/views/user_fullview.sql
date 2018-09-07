DROP VIEW IF EXISTS earmouth.user_fullview CASCADE;
CREATE VIEW earmouth.user_fullview AS
	SELECT u.id,
		u.public_id,
		u.public_name,
		CONCAT('https://earmouth.com/images/', u.public_id, '.jpg') AS image,
		p.city,
		p.state,
		p.country,
		u.bio, (
		SELECT json_agg(x) AS urls
		FROM (
			SELECT id,
				url,
				main
			FROM peeps.urls
			WHERE person_id = u.person_id
			ORDER BY main DESC NULLS LAST, id
		) x)
	FROM earmouth.users u, peeps.people p
	WHERE u.person_id = p.id
	AND u.deleted_at IS NULL;

