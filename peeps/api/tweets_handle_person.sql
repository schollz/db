-- PARAMS: peeps.tweets.id, person_id
-- marks a tweets.handle as being this person
CREATE OR REPLACE FUNCTION peeps.tweets_handle_person(text, integer,
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	UPDATE peeps.tweets
	SET person_id = $2
	WHERE handle = $1;
	SELECT x.status, x.js INTO status, js FROM peeps.tweets_by_person($2) x;
END;
$$ LANGUAGE plpgsql;
