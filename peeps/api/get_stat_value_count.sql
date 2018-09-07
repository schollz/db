--Route{
--  api = "peeps.get_stat_value_count",
--  args = {"name"},
--  method = "GET",
--  url = "/stats/([a-z0-9._-]+)/count",
--  captures = {"name"},
--}
CREATE OR REPLACE FUNCTION peeps.get_stat_value_count(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT statvalue AS value, COUNT(*) AS count
		FROM peeps.stats
		WHERE statkey = $1
		GROUP BY statvalue
		ORDER BY statvalue
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
