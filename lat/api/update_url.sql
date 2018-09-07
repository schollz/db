--Route{
-- api = "lat.update_url",
-- args = {"id", "url", "notes"},
-- method = "PUT",
-- url = "/urls/([0-9]+)",
-- captures = {"id"},
-- params = {"url", "notes"},
--}
CREATE OR REPLACE FUNCTION lat.update_url(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	UPDATE lat.urls
	SET url = $2
	, notes = $3
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM lat.get_url($1) x;

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
