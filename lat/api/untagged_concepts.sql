--Route{
-- api = "lat.untagged_concepts",
-- method = "GET",
-- url = "/concepts/untagged",
-- note = "returns array of concepts or empty array if none found"
--}
CREATE OR REPLACE FUNCTION lat.untagged_concepts(
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js
	FROM lat.get_concepts(ARRAY(
		SELECT lat.concepts.id
		FROM lat.concepts
			LEFT JOIN lat.concepts_tags
			ON lat.concepts.id = lat.concepts_tags.concept_id
		WHERE lat.concepts_tags.tag_id IS NULL
	)) x;
END;
$$ LANGUAGE plpgsql;
