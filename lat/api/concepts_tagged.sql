--Route{
-- api = "lat.concepts_tagged",
-- args = {"tag"},
-- method = "GET",
-- url = "/concepts/tagged",
-- params = {"tag"},
-- note = "returns array of concepts or empty array if none found"
--}
CREATE OR REPLACE FUNCTION lat.concepts_tagged(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js
	FROM lat.get_concepts(ARRAY(
		SELECT concept_id
		FROM lat.concepts_tags, lat.tags
		WHERE lat.tags.tag = $1
		AND lat.tags.id = lat.concepts_tags.tag_id
	)) x;
END;
$$ LANGUAGE plpgsql;
