CREATE OR REPLACE FUNCTION earmouth.get_users(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM earmouth.user_view
		ORDER BY id
	) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;

