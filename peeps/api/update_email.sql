--Route{
--  api = "peeps.update_email",
--  args = {"emailer_id", "email_id", "json"},
--  method = "PUT",
--  url = "/email/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id"},
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.update_email(integer, integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	PERFORM core.jsonupdate('peeps.emails', $2, $3,
		core.cols2update('peeps', 'emails', ARRAY['id', 'created_at']));
	status := 200;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = $2;
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
