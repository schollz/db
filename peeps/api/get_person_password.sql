--Route{
--  api = "peeps.get_person_password",
--  args = {"email", "password"},
--  method = "GET",
--  url = "/person",
--  params = {"email", "password"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person_password(text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	SELECT x.status, x.js INTO status, js
		FROM peeps.get_person(peeps.pid_from_email_pass($1, $2)) x;
END;
$$ LANGUAGE plpgsql;
