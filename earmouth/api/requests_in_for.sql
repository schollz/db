-- PARAMS: users.id
CREATE OR REPLACE FUNCTION earmouth.requests_in_for(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM earmouth.user_view
		WHERE id IN (
			SELECT *
			FROM earmouth.request_in_userids_for($1)
		)
		ORDER BY id DESC
	) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;

