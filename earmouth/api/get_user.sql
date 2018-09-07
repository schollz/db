CREATE OR REPLACE FUNCTION earmouth.get_user(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT * FROM earmouth.user_view
		WHERE id = $1
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;

