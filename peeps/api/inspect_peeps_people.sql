--Route{
--  api = "peeps.inspect_peeps_people",
--  method = "GET",
--  url = "/inspect/people",
--}
CREATE OR REPLACE FUNCTION peeps.inspect_peeps_people(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT c.id, c.person_id, city, state, country, email
		FROM peeps.changelog c
			LEFT JOIN peeps.people p
			ON c.table_id=p.id
		WHERE c.approved IS FALSE
		AND schema_name='peeps'
		AND table_name='people'
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
