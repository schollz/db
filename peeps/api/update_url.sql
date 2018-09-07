--JSON allowed: person_id::int, url::text, main::boolean
--Route{
--  api = "peeps.update_url",
--  args = {"id", "json"},
--  method = "PUT",
--  url = "/urls/([0-9]+)",
--  captures = {"id"},
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.update_url(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	PERFORM core.jsonupdate('peeps.urls', $1, $2,
		core.cols2update('peeps', 'urls', ARRAY['id']));
	js := row_to_json(r.*) FROM peeps.urls r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; END IF;

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
