CREATE OR REPLACE FUNCTION earmouth.user_get_user(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT * FROM earmouth.user_view
		WHERE id = $2
		AND id NOT IN (
			SELECT *
			FROM earmouth.blocked_userids_for($1))
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;

