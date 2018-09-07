--Route{
-- api = "lat.update_concept",
-- args = {"id", "title", "concept"},
-- method = "PUT",
-- url = "/concepts/([0-9]+)",
-- captures = {"id"},
-- params = {"title", "concept"},
--}
CREATE OR REPLACE FUNCTION lat.update_concept(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE lat.concepts
	SET title = $2
	,concept = $3
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js FROM lat.get_concept($1) x;
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
