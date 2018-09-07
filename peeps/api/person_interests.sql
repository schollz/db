-- list of interests and boolean expert flag (not null) for person_id
-- expertises first, wantings last
--Route{
--  api = "peeps.person_interests",
--  args = {"id"},
--  method = "GET",
--  url = "/person/([0-9]+)/interests",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.person_interests(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT interest, expert
		FROM peeps.interests
		WHERE person_id = $1
		ORDER BY expert DESC, interest ASC
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
