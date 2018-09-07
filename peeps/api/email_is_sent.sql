--Route{
--  api = "peeps.email_is_sent",
--  args = {"id"},
--  method = "PUT",
--  url = "/emails/([0-9]+)/sent",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.email_is_sent(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE peeps.emails
	SET outgoing = TRUE
	WHERE id = $1;
	IF NOT FOUND THEN status := 404;
	js := '{}'; RETURN; END IF;
	js := json_build_object('sent', $1);
	status := 200;

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
