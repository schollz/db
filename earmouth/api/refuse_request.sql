-- PARAMS: users.id of requestee, users.id of requester
CREATE OR REPLACE FUNCTION earmouth.refuse_request(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	request_id integer;
BEGIN
	UPDATE earmouth.requests
	SET approved = 'f', closed_at = NOW()
	WHERE requestee = $1
	AND requester = $2
	AND closed_at IS NULL
	RETURNING id INTO request_id;
	IF request_id IS NULL THEN
		status := 404;
		js := '{}';
	ELSE
		status := 200;
		js := json_build_object('id', request_id);
	END IF;
END;
$$ LANGUAGE plpgsql;

