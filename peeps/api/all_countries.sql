-- RETURNS array of objects:
-- [{"code":"AF","name":"Afghanistan"},{"code":"AX","name":"Åland Islands"}..]
--Route{
--  api = "peeps.all_countries",
--  method = "GET",
--  url = "/countries",
--}
CREATE OR REPLACE FUNCTION peeps.all_countries(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (SELECT * FROM peeps.countries ORDER BY name) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;
