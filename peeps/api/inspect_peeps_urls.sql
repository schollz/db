--Route{
--  api = "peeps.inspect_peeps_urls",
--  method = "GET",
--  url = "/inspect/urls",
--}
CREATE OR REPLACE FUNCTION peeps.inspect_peeps_urls(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT c.id, c.person_id, url
		FROM peeps.changelog c
			LEFT JOIN peeps.urls u
			ON c.table_id = u.id
		WHERE c.approved IS FALSE
		AND schema_name = 'peeps'
		AND table_name = 'urls'
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
