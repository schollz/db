-- PARAMS: limit number to see
CREATE OR REPLACE FUNCTION peeps.tweets_unknown_top(integer,
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT handle, entire->'user'->>'name' AS name
		FROM peeps.tweets
		WHERE person_id IS NULL
		GROUP BY handle, name
		ORDER BY COUNT(*) DESC
		LIMIT $1
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
