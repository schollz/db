-- PARAMS: JSON array of integer ids: peeps.changelog.id
--Route{
--  api = "peeps.log_approve",
--  args = {"json"},
--  method = "POST",
--  url = "/inspect",
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.log_approve(json,
	OUT status smallint, OUT js json) AS $$
BEGIN
-- TODO: cast JSON array elements as ::integer instead of casting id::text
	UPDATE peeps.changelog
	SET approved=TRUE
	WHERE id::text IN (
		SELECT * FROM json_array_elements_text($1)
	);
	status := 200;
	js := '{}';
END;
$$ LANGUAGE plpgsql;
