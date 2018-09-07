-- PARAMS: collections.id
CREATE OR REPLACE FUNCTION words.get_collection(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id, filename
		FROM words.articles
		WHERE collection_id = $1
		ORDER BY id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
