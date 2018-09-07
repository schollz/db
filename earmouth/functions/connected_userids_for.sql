-- PARAMS: user_id
CREATE OR REPLACE FUNCTION earmouth.connected_userids_for(integer) RETURNS SETOF integer AS $$
BEGIN
	RETURN QUERY (
	SELECT user1 AS uid
		FROM earmouth.connections
		WHERE revoked_at IS NULL
		AND user2 = $1)
	UNION (
	SELECT user2 AS uid
		FROM earmouth.connections
		WHERE revoked_at IS NULL
		AND user1 = $1);
END;
$$ LANGUAGE plpgsql;

