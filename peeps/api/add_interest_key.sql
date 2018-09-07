--Route{
--  api = "peeps.add_interest_key",
--  args = {"interest"},
--  method = "POST",
--  url = "/interests/([a-z]+)",
--  captures = {"interest"},
--}
CREATE OR REPLACE FUNCTION peeps.add_interest_key(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	INSERT INTO peeps.inkeys(inkey) VALUES ($1);
	SELECT x.status, x.js INTO status, js FROM peeps.interest_keys() x;

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
