--Route{
--  api = "peeps.person_add_interest",
--  args = {"id", "interest"},
--  method = "POST",
--  url = "/person/([0-9]+)/interests/([a-z]+)",
--  captures = {"id", "interest"},
--}
CREATE OR REPLACE FUNCTION peeps.person_add_interest(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	PERFORM 1 FROM peeps.interests
	WHERE person_id = $1
	AND interest = $2;
	IF NOT FOUND THEN
		INSERT INTO peeps.interests(person_id, interest) VALUES ($1, $2);
	END IF;
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
