CREATE OR REPLACE FUNCTION earmouth.delete_user(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	SELECT x.status, x.js INTO status, js FROM earmouth.get_user($1) x;
	UPDATE earmouth.users
		SET deleted_at = NOW()
		WHERE id = $1;
	DELETE FROM earmouth.connections
		WHERE user1 = $1
		OR user2 = $1;
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

