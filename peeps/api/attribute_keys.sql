--Route{
--  api = "peeps.attribute_keys",
--  method = "GET",
--  url = "/attributes",
--}
CREATE OR REPLACE FUNCTION peeps.attribute_keys(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT atkey, description
		FROM peeps.atkeys
		ORDER BY atkey
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;
