--Route{
--  api = "peeps.make_newpass",
--  args = {"person_id"},
--  method = "POST",
--  url = "/password/([0-9]+)",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.make_newpass(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE peeps.people
		SET newpass = core.unique_for_table_field(8, 'peeps.people', 'newpass')
		WHERE id = $1
		AND newpass IS NULL;
	SELECT json_build_object('id', id, 'newpass', newpass) INTO js
		FROM peeps.people
		WHERE id = $1;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
