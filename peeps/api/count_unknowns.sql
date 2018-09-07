--Route{
--  api = "peeps.count_unknowns",
--  args = {"emailer_id"},
--  method = "GET",
--  url = "/unknowns/([0-9]+)/count",
--  captures = {"emailer_id"},
--}
CREATE OR REPLACE FUNCTION peeps.count_unknowns(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_build_object('count', (
		SELECT COUNT(*) FROM peeps.unknown_email_ids($1)
	));
	status := 200;
END;
$$ LANGUAGE plpgsql;
