CREATE OR REPLACE FUNCTION earmouth.user_get_users(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM earmouth.user_view
		WHERE id != $1
		AND id NOT IN (
			SELECT *
			FROM earmouth.blocked_userids_for($1))
		ORDER BY id
	) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;

