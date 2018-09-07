--Route{
-- api = "lat.create_pairing",
-- method = "POST",
-- url = "/pairings",
-- note = "randomly generated"
--}
CREATE OR REPLACE FUNCTION lat.create_pairing(
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	SELECT id INTO pid FROM lat.new_pairing();
	SELECT x.status, x.js INTO status, js FROM lat.get_pairing(pid) x;

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
