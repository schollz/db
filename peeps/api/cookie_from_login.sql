--Route{
--  api = "peeps.cookie_from_login",
--  args = {"email", "password", "domain"},
--  method = "POST",
--  url = "/login/([a-z0-9.-]+)",
--  captures = {"domain"},
--  params = {"email", "password"},
--}
CREATE OR REPLACE FUNCTION peeps.cookie_from_login(text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT p.pid INTO pid FROM peeps.pid_from_email_pass($1, $2) p;
	IF pid IS NULL THEN status := 404;
	js := '{}'; RETURN; END IF;
	SELECT x.status, x.js INTO status, js FROM peeps.cookie_from_id(pid, $3) x;
END;
$$ LANGUAGE plpgsql;
