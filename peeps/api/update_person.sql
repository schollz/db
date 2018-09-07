--Route{
--  api = "peeps.update_person",
--  args = {"person_id", "json"},
--  method = "PUT",
--  url = "/person/([0-9]+)",
--  captures = {"person_id"},
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.update_person(integer, json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	PERFORM core.jsonupdate('peeps.people',
		$1,
		$2,
		core.cols2update('peeps', 'people', ARRAY['id', 'created_at']));
	SELECT x.status, x.js INTO status, js FROM peeps.get_person($1) x;

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
