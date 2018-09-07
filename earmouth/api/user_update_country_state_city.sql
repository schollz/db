-- PARAMS: users.id, country code, state code or NULL, city
CREATE OR REPLACE FUNCTION earmouth.user_update_country_state_city(integer, text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE peeps.people
	SET country = $2,
		state = $3,
		city = $4
	WHERE id = (
		SELECT person_id
		FROM earmouth.users
		WHERE id = $1
	);
	SELECT x.status, x.js INTO status, js FROM earmouth.get_user($1) x;
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

