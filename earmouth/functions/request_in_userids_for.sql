-- PARAMS: user_id
CREATE OR REPLACE FUNCTION earmouth.request_in_userids_for(integer) RETURNS SETOF integer AS $$
BEGIN
	RETURN QUERY (
		SELECT requester
		FROM earmouth.requests
		WHERE requestee = $1
		AND approved IS NULL
	);
END;
$$ LANGUAGE plpgsql;

