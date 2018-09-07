--Route{
--  api = "peeps.get_person_cookie",
--  args = {"cookie"},
--  method = "GET",
--  url = "/person/([a-zA-Z0-9]{32}",
--  captures = {"cookie"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person_cookie(text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js
		FROM peeps.get_person(peeps.get_person_id_from_cookie($1)) x;
END;
$$ LANGUAGE plpgsql;
