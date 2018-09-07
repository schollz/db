-- PARAMS: user_id
CREATE OR REPLACE FUNCTION earmouth.unconnected_userids_for(integer) RETURNS SETOF integer AS $$
BEGIN
	RETURN QUERY (
		SELECT id
		FROM earmouth.users
		WHERE id != $1
		AND id NOT IN (
			SELECT * FROM earmouth.connected_userids_for($1)
		)
		AND id NOT IN (
			SELECT * FROM earmouth.blocked_userids_for($1)
		)
		AND id NOT IN (
			SELECT * FROM earmouth.request_in_userids_for($1)
		)
		AND id NOT IN (
			SELECT * FROM earmouth.request_out_userids_for($1)
		)
	);
END;
$$ LANGUAGE plpgsql;

