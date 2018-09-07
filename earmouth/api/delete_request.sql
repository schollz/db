-- PARAMS: users.id of requester, users.id of reqestee
CREATE OR REPLACE FUNCTION earmouth.delete_request(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	request_id integer;
BEGIN
	DELETE FROM earmouth.requests
	WHERE requester = $1
	AND requestee = $2
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

