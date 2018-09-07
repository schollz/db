--Route{
--  api = "peeps.cookie_from_id",
--  args = {"person_id", "domain"},
--  method = "POST",
--  url = "/login/([0-9]+)/([a-z0-9.-]+)",
--  captures = {"person_id", "domain"},
--}
CREATE OR REPLACE FUNCTION peeps.cookie_from_id(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT cookie FROM peeps.login_person_domain($1, $2)
	) r;

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
