DROP VIEW IF EXISTS earmouth.user_view CASCADE;
CREATE VIEW earmouth.user_view AS
	SELECT u.id,
		u.public_id,
		u.public_name,
		CONCAT('https://earmouth.com/images/', u.public_id, '.jpg') AS image,
		p.city,
		p.state,
		p.country,
		u.bio
	FROM earmouth.users u, peeps.people p
	WHERE u.person_id = p.id
	AND u.deleted_at IS NULL;

