--Route{
--  api = "peeps.inspect_now_urls",
--  method = "GET",
--  url = "/inspect/now",
--}
CREATE OR REPLACE FUNCTION peeps.inspect_now_urls(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT c.id, c.person_id, short, long
		FROM peeps.changelog c
			LEFT JOIN now.urls u
			ON c.table_id = u.id
		WHERE c.approved IS FALSE
		AND schema_name = 'now'
		AND table_name = 'urls'
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
