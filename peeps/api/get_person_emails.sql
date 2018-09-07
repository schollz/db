--Route{
--  api = "peeps.get_person_emails",
--  args = {"person_id"},
--  method = "GET",
--  url = "/person/([0-9]+)/emails",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.get_person_emails(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.emails_full_view
		WHERE person_id = $1
		ORDER BY id
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
