--Route{
--  api = "peeps.state_count",
--  args = {"country"},
--  method = "GET",
--  url = "/where/([A-Z]{2})/states",
--  captures = {"country"},
--}
CREATE OR REPLACE FUNCTION peeps.state_count(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT state, COUNT(*)
		FROM peeps.people
		WHERE country = $1
		AND state IS NOT NULL
		AND state != ''
		GROUP BY state
		ORDER BY COUNT(*) DESC, state
	) r;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
