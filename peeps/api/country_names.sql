-- RETURNS single code:name object:
-- {"AD":"Andorra","AE":"United Arab Emirates...  }
--Route{
--  api = "peeps.country_names",
--  method = "GET",
--  url = "/country/names",
--}
CREATE OR REPLACE FUNCTION peeps.country_names(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_object(
		ARRAY(SELECT code FROM peeps.countries ORDER BY code),
		ARRAY(SELECT name FROM peeps.countries ORDER BY code));
	status := 200;
END;
$$ LANGUAGE plpgsql;
