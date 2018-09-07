--Route{
--  api = "peeps.get_stats",
--  args = {"name", "value"},
--  method = "GET",
--  url = "/stats/([a-z0-9._-]+)/value/(.+)",
--  captures = {"name", "value"},
--}
CREATE OR REPLACE FUNCTION peeps.get_stats(text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.stats_view
		WHERE name = $1
		AND value = $2
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.get_stats",
--  args = {"name"},
--  method = "GET",
--  url = "/stats/([a-z0-9._-]+)",
--  captures = {"name"},
--}
CREATE OR REPLACE FUNCTION peeps.get_stats(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT * FROM peeps.stats_view WHERE name = $1
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
