-- PARAMS: person_id
CREATE OR REPLACE FUNCTION peeps.tweets_by_person(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id, created_at, message, reference_id
		FROM peeps.tweets
		WHERE person_id = $1
		ORDER BY id DESC
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
