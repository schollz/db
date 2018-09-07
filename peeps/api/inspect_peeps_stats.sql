--Route{
--  api = "peeps.inspect_peeps_stats",
--  method = "GET",
--  url = "/inspect/stats",
--}
CREATE OR REPLACE FUNCTION peeps.inspect_peeps_stats(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT c.id, c.person_id, statkey, statvalue
		FROM peeps.changelog c
			LEFT JOIN peeps.stats s
			ON c.table_id = s.id
		WHERE c.approved IS FALSE
		AND schema_name = 'peeps'
		AND table_name = 'stats'
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
