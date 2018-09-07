--Route{
--  api = "peeps.create_person",
--  args = {"name", "email"},
--  method = "POST",
--  url = "/person",
--  params = {"name", "email"},
--}
CREATE OR REPLACE FUNCTION peeps.create_person(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	SELECT id INTO pid FROM peeps.person_create($1, $2);
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = pid;
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
