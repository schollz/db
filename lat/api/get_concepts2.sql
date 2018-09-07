--Route{
-- api = "lat.get_concepts",
-- args = {"ids"},
-- method = "GET",
-- url = "/concepts/multi",
-- params = {"ids"},
-- note = "array of concept IDs"
--}
CREATE OR REPLACE FUNCTION lat.get_concepts(integer[],
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM lat.concept_view
		WHERE id = ANY($1)
		ORDER BY id
	) r;
	IF js IS NULL THEN js := '[]'; END IF; -- If none found, js is empty array
END;
$$ LANGUAGE plpgsql;
