--Route{
--  api = "peeps.inspections_grouped",
--  method = "GET",
--  url = "/inspect",
--}
CREATE OR REPLACE FUNCTION peeps.inspections_grouped(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT schema_name, table_name, COUNT(*)
		FROM peeps.changelog
		WHERE approved IS FALSE
		GROUP BY schema_name, table_name
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
