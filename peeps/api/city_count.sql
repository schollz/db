--Route{
--  api = "peeps.city_count",
--  args = {"country", "state"},
--  method = "GET",
--  url = "/where/([A-Z]{2})/([^/]+)/cities",
--  captures = {"country", "state"},
--}
CREATE OR REPLACE FUNCTION peeps.city_count(char(2), text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT city, COUNT(*)
		FROM peeps.people
		WHERE country = $1
		AND state = $2
		AND (city IS NOT NULL AND city != '')
		GROUP BY city
		ORDER BY COUNT(*) DESC, city
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;


--Route{
--  api = "peeps.city_count",
--  args = {"country"},
--  method = "GET",
--  url = "/where/([A-Z]{2})/cities",
--  captures = {"country"},
--}
CREATE OR REPLACE FUNCTION peeps.city_count(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT city, COUNT(*)
		FROM peeps.people
		WHERE country = $1
		AND (city IS NOT NULL AND city != '')
		GROUP BY city
		ORDER BY COUNT(*) DESC, city
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;
