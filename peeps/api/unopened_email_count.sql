-- Grouped summary of howmany unopened emails in each profile/category
-- JSON format: {profiles:{categories:howmany}}
--{"sivers":{"sivers":43,"derek":2,"programmer":1},
-- "woodegg":{"woodeggRESEARCH":1,"woodegg":1}}
--Route{
--  api = "peeps.unopened_email_count",
--  args = {"emailer_id"},
--  method = "GET",
--  url = "/unopened/([0-9]+)",
--  captures = {"emailer_id"},
--}
CREATE OR REPLACE FUNCTION peeps.unopened_email_count(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_object_agg(profile, cats) FROM (
		WITH unopened AS (
			SELECT profile, category
			FROM peeps.emails
			WHERE id IN (
				SELECT * FROM peeps.unopened_email_ids($1)
			)
		)
		SELECT profile, (
			SELECT json_object_agg(category, num)
			FROM (
				SELECT category, COUNT(*) AS num
				FROM unopened u2
				WHERE u2.profile = unopened.profile
				GROUP BY category
				ORDER BY num DESC
			)
		rr) AS cats
		FROM unopened
		GROUP BY profile
	) r;  
	status := 200;
	IF js IS NULL THEN js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
