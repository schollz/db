-- PARAMS: twitter handle like '@whatEver' (with or without @)
CREATE OR REPLACE FUNCTION peeps.pid_for_twitter_handle(text, OUT pid integer) AS $$
	SELECT person_id AS pid
	FROM peeps.urls
	WHERE url LIKE '%/twitter.com/%'
	AND lower(regexp_replace(url, '^.*/', '')) = lower(replace($1, '@', ''))
	ORDER BY id ASC
	LIMIT 1;
$$ LANGUAGE sql;
