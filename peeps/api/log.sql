--Route{
--  api = "peeps.log",
--  args = {"person_id", "schema", "table", "id"},
--  method = "POST",
--  url = "/log/([0-9]+)/([a-z]+)/([a-z_]+)/([0-9]+)",
--  captures = {"person_id", "schema", "table", "id"},
--}
CREATE OR REPLACE FUNCTION peeps.log(integer, text, text, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := '{}';
	INSERT INTO peeps.changelog(person_id, schema_name, table_name, table_id)
		VALUES($1, $2, $3, $4);
END;
$$ LANGUAGE plpgsql;
