--Route{
--  api = "peeps.get_formletters",
--  method = "GET",
--  url = "/formletters",
--}
CREATE OR REPLACE FUNCTION peeps.get_formletters(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.formletters_view
		ORDER BY accesskey, title
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;
