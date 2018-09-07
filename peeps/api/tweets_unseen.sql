-- PARAMS: limit number to see
CREATE OR REPLACE FUNCTION peeps.tweets_unseen(integer,
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id,
			handle,
			person_id,
			message,
			entire->'user'->>'name' AS name
		FROM peeps.tweets
		WHERE seen IS NOT TRUE
		ORDER BY id DESC
		LIMIT $1
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
