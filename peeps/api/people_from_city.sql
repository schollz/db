--Route{
--  api = "peeps.people_from_city",
--  args = {"country", "city"},
--  method = "GET",
--  url = "/where/([A-Z]{2})/city/([^/]+)/people",
--  captures = {"country", "city"},
--}
CREATE OR REPLACE FUNCTION peeps.people_from_city(char(2), text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.people_view
		WHERE id IN (
			SELECT id
			FROM peeps.people
			WHERE country = $1
			AND city = $2
		)
		ORDER BY email_count DESC, name
	) r;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
