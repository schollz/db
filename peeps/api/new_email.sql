--Route{
--  api = "peeps.new_email",
--  args = {"emailer_id", "person_id", "profile", "subject", "body"},
--  method = "POST",
--  url = "/person/([0-9]+)/emails/([0-9]+)",
--  captures = {"person_id", "emailer_id"},
--  params = {"profile", "subject", "body"},
--}
CREATE OR REPLACE FUNCTION peeps.new_email(integer, integer, text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	-- PARAMS: emailer_id, person_id, profile, category, subject, body, reference_id (NULL unless reply)
	SELECT * INTO new_id FROM peeps.outgoing_email($1, $2, $3, $3, $4, $5, NULL);
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = new_id;
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
