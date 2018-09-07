-- use to set expert flag to existing
--Route{
--  api = "peeps.person_update_interest",
--  args = {"id", "interest", "true"},
--  method = "POST",
--  url = "/person/([0-9]+)/interests/([a-z]+)/plus",
--  captures = {"id", "interest"},
--}
CREATE OR REPLACE FUNCTION peeps.person_update_interest(integer, text, boolean,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE peeps.interests
	SET expert = $3
	WHERE person_id = $1
	AND interest = $2;
	SELECT x.status, x.js INTO status, js FROM peeps.person_interests($1) x;

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
