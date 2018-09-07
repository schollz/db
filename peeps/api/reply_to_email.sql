--Route{
--  api = "peeps.reply_to_email",
--  args = {"emailer_id", "email_id", "body"},
--  method = "PUT",
--  url = "/email/([0-9]+)/([0-9]+)",
--  captures = {"emailer_id", "email_id"},
--  params = {"body"},
--}
CREATE OR REPLACE FUNCTION peeps.reply_to_email(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	e peeps.emails;
	new_id integer;
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	IF $3 IS NULL OR (regexp_replace($3, '\s', '', 'g') = '') THEN
		RAISE 'body must not be empty';
	END IF;
	SELECT * INTO e FROM peeps.emails WHERE id = $2;
	IF e IS NULL THEN
		status := 404;
		js := '{}';
		RETURN;
	END IF;
	-- PARAMS: emailer_id, person_id, profile, category, subject, body, reference_id 
	SELECT * INTO new_id
	FROM peeps.outgoing_email($1,
		e.person_id,
		e.profile,
		e.profile,
		concat('re: ', regexp_replace(e.subject, 're: ', '', 'ig')),
		$3,
		$2);
	UPDATE peeps.emails
	SET answer_id = new_id, closed_at = NOW(), closed_by = $1
	WHERE id = $2;
	js := json_build_object('id', new_id);
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
