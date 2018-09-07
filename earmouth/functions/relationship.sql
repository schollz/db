-- PARAMS: users1.id, users2.id
-- (user1 = who's asking.  user2 = who they're asking about)
CREATE OR REPLACE FUNCTION earmouth.relationship_from_to(integer, integer) RETURNS text AS $$
DECLARE
	yesno integer;
BEGIN
	IF $1 = $2 THEN RETURN 'self'; END IF;
	-- "connection-request-out"
	SELECT id INTO yesno
		FROM earmouth.requests
		WHERE requester = $1
		AND requestee = $2
		AND approved IS NULL;
	IF yesno IS NOT NULL THEN RETURN 'connection-request-out'; END IF;
	-- "connection-request-in"
	SELECT id INTO yesno
		FROM earmouth.requests
		WHERE requester = $2
		AND requestee = $1
		AND approved IS NULL;
	IF yesno IS NOT NULL THEN RETURN 'connection-request-in'; END IF;
	-- "blocked"
	SELECT id INTO yesno
		FROM earmouth.requests
		WHERE ((requester = $1
		AND requestee = $2) OR (requester = $2
		AND requestee = $1))
		AND approved IS FALSE;
	IF yesno IS NOT NULL THEN RETURN 'blocked'; END IF;
	-- "blocked"
	SELECT id INTO yesno
		FROM earmouth.connections
		WHERE ((user1 = $1
		AND user2 = $2) OR (user1 = $2
		AND user2 = $1))
		AND revoked_at IS NOT NULL;
	IF yesno IS NOT NULL THEN RETURN 'blocked'; END IF;
	-- "connected"
	SELECT id INTO yesno
		FROM earmouth.connections
		WHERE ((user1 = $1
		AND user2 = $2) OR (user1 = $2
		AND user2 = $1))
		AND revoked_at IS NULL;
	IF yesno IS NOT NULL THEN RETURN 'connected';
	-- else "unconnected"
	ELSE
		return 'unconnected';
	END IF;
END;
$$ LANGUAGE plpgsql;

