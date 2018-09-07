--Route{
--  api = "peeps.merge_person",
--  args = {"keeper_id", "old_id"},
--  method = "POST",
--  url = "/merge/([0-9]+)/([0-9]+)",
--  captures = {"keeper_id", "old_id"},
--}
CREATE OR REPLACE FUNCTION peeps.merge_person(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	PERFORM peeps.person_merge_from_to($2, $1);
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = $1;
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
