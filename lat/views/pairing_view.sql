DROP VIEW IF EXISTS lat.pairing_view CASCADE;
CREATE VIEW lat.pairing_view AS
	SELECT id,
	created_at,
	thoughts, (
		SELECT row_to_json(c1.*) AS concept1
		FROM lat.concept_view c1
		WHERE id = lat.pairings.concept1_id
	), (
		SELECT row_to_json(c2.*) AS concept2
		FROM lat.concept_view c2
		WHERE id = lat.pairings.concept2_id
	)
	FROM lat.pairings;

