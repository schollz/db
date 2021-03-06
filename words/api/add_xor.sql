-- PARAMS: person_id, lang
CREATE OR REPLACE FUNCTION words.add_xor(integer, char(2),
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	tid smallint;
BEGIN
	INSERT INTO words.translators(person_id, lang)
	VALUES ($1, $2)
	RETURNING id INTO tid;
	status := 200;
	js := row_to_json(r) FROM (
		SELECT *
		FROM words.translators
		WHERE id = tid) r;
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
