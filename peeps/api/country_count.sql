--Route{
--  api = "peeps.country_count",
--  method = "GET",
--  url = "/country/count",
--}
CREATE OR REPLACE FUNCTION peeps.country_count(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT country, COUNT(*)
		FROM peeps.people
		WHERE country IS NOT NULL
		GROUP BY country
		ORDER BY COUNT(*) DESC, country
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;
