-- PARAMS: users.id requesting revokation, other users.id 
CREATE OR REPLACE FUNCTION earmouth.revoke_connection(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	connection_id integer;
BEGIN
	UPDATE earmouth.connections
	SET revoked_at = NOW(), revoked_by = $1
	WHERE ((user1 = $1 AND user2 = $2)
	OR (user2 = $1 AND user1 = $2))
	AND revoked_at IS NULL
	RETURNING id INTO connection_id;
	IF connection_id IS NULL THEN
		status := 404;
		js := '{}';
	ELSE
		status := 200;
		js := json_build_object('id', connection_id);
	END IF;
END;
$$ LANGUAGE plpgsql;

