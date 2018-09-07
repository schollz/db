--Route{
--  api = "peeps.person_delete_interest",
--  args = {"id", "interest"},
--  method = "DELETE",
--  url = "/person/([0-9]+)/interests/([a-z]+)",
--  captures = {"id", "interest"},
--}
CREATE OR REPLACE FUNCTION peeps.person_delete_interest(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	DELETE FROM peeps.interests
	WHERE person_id = $1
	AND interest = $2;
	SELECT x.status, x.js INTO status, js FROM peeps.person_interests($1) x;
END;
$$ LANGUAGE plpgsql;
