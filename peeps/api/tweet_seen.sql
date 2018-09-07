-- PARAMS: peeps.tweets.id
-- marks a tweet as seen
CREATE OR REPLACE FUNCTION peeps.tweet_seen(bigint,
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	UPDATE peeps.tweets
	SET seen = TRUE
	WHERE id = $1;
	status := 200;
	js := '{}';
END;
$$ LANGUAGE plpgsql;
