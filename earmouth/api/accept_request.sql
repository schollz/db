-- Can use this to go back and accept a request previously refused
-- PARAMS: users.id of requestee, users.id of requester
CREATE OR REPLACE FUNCTION earmouth.accept_request(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	request_id integer;
	connection_id integer;
BEGIN
	UPDATE earmouth.requests
	SET approved = 't', closed_at = NOW()
	WHERE requestee = $1
	AND requester = $2
	RETURNING id INTO request_id;
	IF request_id IS NULL THEN
		status := 404;
		js := '{}';
	ELSE
		-- already connected? quietly skip insert
		SELECT id INTO connection_id
		FROM earmouth.connections
		WHERE (earmouth.sort(array[user1, user2])) = earmouth.sort(array[$1, $2]);
		IF connection_id IS NULL THEN
			INSERT INTO earmouth.connections (user1, user2)
			VALUES ($1, $2);
		END IF;
		SELECT x.status, x.js INTO status, js FROM earmouth.get_user($2) x;
	END IF;
END;
$$ LANGUAGE plpgsql;

