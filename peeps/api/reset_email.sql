-- sets newpass if none, sends email if not already sent recently
--Route{
--  api = "peeps.reset_email",
--  args = {"formletter_id", "email"},
--  method = "POST",
--  url = "/reset_email/([0-9]+)",
--  captures = {"formletter_id"},
--  params = {"email"},
--}
CREATE OR REPLACE FUNCTION peeps.reset_email(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	SELECT id INTO pid FROM peeps.get_person_id_from_email($2);
	IF pid IS NULL THEN status := 404;
	js := '{}'; ELSE
		PERFORM peeps.make_newpass(pid);
		SELECT x.status, x.js INTO status, js
		FROM peeps.send_person_formletter(pid, $1, 'sivers') x;
	END IF;
END;
$$ LANGUAGE plpgsql;
