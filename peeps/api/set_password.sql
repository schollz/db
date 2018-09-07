--Route{
--  api = "peeps.set_password",
--  args = {"person_id", "password"},
--  method = "PUT",
--  url = "/person/([0-9]+)/password",
--  captures = {"person_id"},
--  params = {"password"},
--}
CREATE OR REPLACE FUNCTION peeps.set_password(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	PERFORM peeps.set_hashpass($1, $2);
	SELECT x.status, x.js INTO status, js FROM peeps.get_person($1) x;

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
