-- NOTE: plusminus but NOT be NULL (unlike interests.expert param)
--Route{
--  api = "peeps.people_with_attribute",
--  args = {"attribute", "plusminus"},
--  method = "GET",
--  url = "/people/attribute",
--  params = {"attribute", "plusminus"},
--}
CREATE OR REPLACE FUNCTION peeps.people_with_attribute(text, boolean,
	OUT status smallint, OUT js json) AS $$
BEGIN
	-- if plusminus is null, return 404 instead of query
	IF $2 IS NULL THEN status := 404;
	js := '{}'; RETURN; END IF;
	-- if invalid attribute key, return 404 instead of query
	PERFORM 1 FROM peeps.atkeys WHERE atkey = $1;
	IF NOT FOUND THEN status := 404;
	js := '{}'; RETURN; END IF;
	status := 200;
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.people_view
		WHERE id IN (
			SELECT person_id
			FROM peeps.attributes
			WHERE attribute = $1
			AND plusminus = $2
		)
		ORDER BY email_count DESC, id DESC
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
