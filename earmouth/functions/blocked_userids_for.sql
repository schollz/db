-- PARAMS: user_id
CREATE OR REPLACE FUNCTION earmouth.blocked_userids_for(integer) RETURNS SETOF integer AS $$
BEGIN
	RETURN QUERY (
	SELECT user1 AS uid
		FROM earmouth.connections
		WHERE revoked_at IS NOT NULL
		AND user2 = $1)
	UNION (
	SELECT user2 AS uid
		FROM earmouth.connections
		WHERE revoked_at IS NOT NULL
		AND user1 = $1)
	UNION (
	SELECT requestee AS uid
		FROM earmouth.requests
		WHERE requester = $1
		AND approved = 'f');
END;
$$ LANGUAGE plpgsql;

