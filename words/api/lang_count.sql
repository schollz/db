CREATE OR REPLACE FUNCTION words.lang_count(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT lang,
		COUNT(CASE WHEN yesno IS NULL THEN 1 END) AS yn,
		COUNT(CASE WHEN yesno IS TRUE THEN 1 END) AS y,
		COUNT(CASE WHEN yesno IS FALSE THEN 1 END) AS n
		FROM words.candidates
		WHERE has_emailed IS TRUE
		GROUP BY lang ORDER BY lang
	) r;
END;
$$ LANGUAGE plpgsql;
