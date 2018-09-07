--Route{
-- api = "lat.create_concept",
-- args = {"title", "concept"},
-- method = "POST",
-- url = "/concepts",
-- params = {"title", "concept"},
--}
CREATE OR REPLACE FUNCTION lat.create_concept(text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	new_id integer;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	INSERT INTO lat.concepts(title, concept)
	VALUES ($1, $2)
	RETURNING id INTO new_id;
	SELECT x.status, x.js INTO status, js FROM lat.get_concept(new_id) x;

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
