--Route{
--  api = "peeps.people_with_interest",
--  args = {"interest", "expert"},
--  method = "GET",
--  url = "/people/interest",
--  params = {"interest", "expert"},
--}
CREATE OR REPLACE FUNCTION peeps.people_with_interest(text, boolean,
	OUT status smallint, OUT js json) AS $$
BEGIN
	-- if invalid interest key, return 404 instead of query
	PERFORM 1 FROM peeps.inkeys WHERE inkey = $1;
	IF NOT FOUND THEN status := 404;
	js := '{}'; RETURN; END IF;
	status := 200;
	-- if 2nd param is NULL then ignore expert flag, else use it
	IF $2 IS NULL THEN
		js := json_agg(r) FROM (
			SELECT *
			FROM peeps.people_view
			WHERE id IN (
				SELECT person_id
				FROM peeps.interests
				WHERE interest = $1
			)
			ORDER BY email_count DESC, id DESC
		) r;
	ELSE
		js := json_agg(r) FROM (
			SELECT *
			FROM peeps.people_view
			WHERE id IN (
				SELECT person_id
				FROM peeps.interests
				WHERE interest = $1
				AND expert = $2
			)
			ORDER BY email_count DESC, id DESC
		) r;
	END IF;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
