-- PARAMS: user_id
CREATE OR REPLACE FUNCTION earmouth.request_out_userids_for(integer) RETURNS SETOF integer AS $$
BEGIN
	RETURN QUERY (
		SELECT requestee
		FROM earmouth.requests
		WHERE requester = $1
		AND approved IS NULL
	);
END;
$$ LANGUAGE plpgsql;

