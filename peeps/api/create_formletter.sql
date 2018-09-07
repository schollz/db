--Route{
--  api = "peeps.create_formletter",
--  args = {"title"},
--  method = "POST",
--  url = "/formletters",
--  params = {"title"},
--}
CREATE OR REPLACE FUNCTION peeps.create_formletter(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	INSERT INTO peeps.formletters(title) VALUES ($1) RETURNING id INTO new_id;
	js := row_to_json(r.*) FROM peeps.formletter_view r WHERE id = new_id;
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
