-- PARAMS: tweets.id
CREATE OR REPLACE FUNCTION peeps.get_tweet(bigint,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT id,
			created_at,
			person_id,
			handle,
			message,
			reference_id,
			seen
		FROM peeps.tweets
		WHERE id = $1
	) r;
	IF js IS NULL THEN status := 404;
	js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
