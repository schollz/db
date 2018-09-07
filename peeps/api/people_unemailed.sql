--Route{
--  api = "peeps.people_unemailed",
--  method = "GET",
--  url = "/people/unemailed",
--}
CREATE OR REPLACE FUNCTION peeps.people_unemailed(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.people_view
		WHERE email_count = 0
		ORDER BY id DESC
		LIMIT 200
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;
