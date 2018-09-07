-- PARAMS: apiuser, apipass
CREATE OR REPLACE FUNCTION earmouth.auth_user(text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT id
		FROM earmouth.users
		WHERE apiuser = $1
		AND apipass = $2) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;

