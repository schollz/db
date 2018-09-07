--Route{
--  api = "peeps.person_set_attribute",
--  args = {"id", "attribute", "false"},
--  method = "PUT",
--  url = "/person/([0-9]+)/attributes/([a-z-]+)/minus",
--  captures = {"id", "attribute"},
--}
CREATE OR REPLACE FUNCTION peeps.person_delete_attribute(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	DELETE FROM peeps.attributes
	WHERE person_id = $1
	AND attribute = $2;
	SELECT x.status, x.js INTO status, js FROM peeps.person_attributes($1) x;
END;
$$ LANGUAGE plpgsql;
