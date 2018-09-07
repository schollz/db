DROP VIEW IF EXISTS lat.concept_view CASCADE;
CREATE VIEW lat.concept_view AS
	SELECT id,
	created_at,
	title,
	concept, (
		SELECT json_agg(uq) AS urls FROM (
			SELECT u.*
			FROM lat.urls u
			, lat.concepts_urls cu
			WHERE u.id = cu.url_id
			AND cu.concept_id = lat.concepts.id
			ORDER BY u.id
		)
	uq), (
		SELECT json_agg(tq) AS tags FROM (
			SELECT t.*
			FROM lat.tags t
			, lat.concepts_tags ct
			WHERE t.id = ct.tag_id
			AND ct.concept_id = concepts.id
			ORDER BY t.id
		)
	tq)
	FROM lat.concepts;
