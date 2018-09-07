-- PARAMS: candidates.id, lang, role, expert, yesno, notes
CREATE OR REPLACE FUNCTION words.update_candidate(integer, char(2), char(3), char(3), boolean, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE words.candidates
	SET lang = $2,
		role = $3,
		expert = $4,
		yesno = $5,
		notes = $6
	WHERE id = $1;
	status := 200;
	js := json_build_object('id', $1);
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
