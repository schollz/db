--Route{
-- api = "lat.get_concepts",
-- method = "GET",
-- url = "/concepts",
--}
CREATE OR REPLACE FUNCTION lat.get_concepts(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM lat.concepts
		ORDER BY id
	) r;
END;
$$ LANGUAGE plpgsql;
