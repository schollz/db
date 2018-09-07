CREATE OR REPLACE FUNCTION words.get_collections(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id, name
		FROM words.collections
		ORDER BY id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
