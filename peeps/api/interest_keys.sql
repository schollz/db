--Route{
--  api = "peeps.interest_keys",
--  method = "GET",
--  url = "/interests",
--}
CREATE OR REPLACE FUNCTION peeps.interest_keys(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT inkey, description
		FROM peeps.inkeys
		ORDER BY inkey
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;
