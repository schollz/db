--returns array of {person_id: 1234, twitter: 'username'}
--Route{
--  api = "peeps.twitter_unfollowed",
--  method = "GET",
--  url = "/twitter/unfollowed",
--}
CREATE OR REPLACE FUNCTION peeps.twitter_unfollowed(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT person_id,
		regexp_replace(regexp_replace(url, 'https?://twitter.com/', ''), '/$', '')
		AS twitter
		FROM peeps.urls
		WHERE url LIKE '%twitter.com%'
		AND person_id NOT IN (
			SELECT person_id
			FROM peeps.stats
			WHERE statkey = 'twitter'
		)
	) r;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
