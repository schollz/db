-- PARAMS: name, email, lang, role, expert
CREATE OR REPLACE FUNCTION words.add_candidate(text, text, char(2), char(3), char(3),
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	SELECT id INTO pid FROM peeps.person_create($1, $2);
	INSERT INTO words.candidates(person_id, lang, role, expert)
	VALUES (pid, $3, $4, $5);
	status := 200;
	js := json_build_object('person_id', pid);
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
