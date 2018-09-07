--Route{
--  api = "peeps.get_unknowns",
--  args = {"emailer_id"},
--  method = "GET",
--  url = "/unknowns/([0-9]+)",
--  captures = {"emailer_id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_unknowns(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.emails_view
		WHERE id IN (
			SELECT * FROM peeps.unknown_email_ids($1)
		)
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
