-- PARAMS : code, comment
CREATE OR REPLACE FUNCTION words.update_sentence_comment(char(8), text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE words.sentences
	SET comment = $2
	WHERE code = $1;
	status := 200;
	js := '{}';
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
END
$$ LANGUAGE plpgsql;
