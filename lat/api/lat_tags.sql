--Route{
-- api = "lat.tags",
-- method = "GET",
-- url = "/tags",
--}
CREATE OR REPLACE FUNCTION lat.tags(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM lat.tags
		ORDER BY RANDOM()
	) r;
END;
$$ LANGUAGE plpgsql;
