-- PARAMS: users.id of requester, users.id of requestee
CREATE OR REPLACE FUNCTION earmouth.create_request(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	connection_id integer;
	request_id integer;
BEGIN
	-- already connected? refuse
	SELECT id INTO connection_id
	FROM earmouth.connections
	WHERE (earmouth.sort(array[user1, user2])) = earmouth.sort(array[$1, $2]);
	IF connection_id IS NOT NULL THEN
		RAISE 'already_connected';
	ELSE
		INSERT INTO earmouth.requests (requester, requestee)
		VALUES ($1, $2)
		RETURNING id INTO request_id;
		status := 200;
		js := json_build_object('id', request_id);
	END IF;
EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);
END;
$$ LANGUAGE plpgsql;

