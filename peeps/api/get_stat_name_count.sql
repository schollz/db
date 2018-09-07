--Route{
--  api = "peeps.get_stat_name_count",
--  method = "GET",
--  url = "/stats",
--}
CREATE OR REPLACE FUNCTION peeps.get_stat_name_count(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT statkey AS name, COUNT(*) AS count
		FROM peeps.stats
		GROUP BY statkey
		ORDER BY statkey
	) r;
END;
$$ LANGUAGE plpgsql;
