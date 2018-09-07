--Route{
--  api = "peeps.get_next_unknown",
--  args = {"emailer_id"},
--  method = "GET",
--  url = "/unknowns/([0-9]+)/next",
--  captures = {"emailer_id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_next_unknown(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.unknown_view r
	WHERE id IN (
		SELECT * FROM peeps.unknown_email_ids($1)
		LIMIT 1
	);
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
