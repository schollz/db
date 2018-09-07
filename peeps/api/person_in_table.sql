--Route{
--  api = "peeps.person_in_table",
--  args = {"person_id", "schema.table"},
--  method = "GET",
--  url = "/person/([0-9]+)/([a-z0-9.]+)",
--  captures = {"person_id", "tablename"},
--}
CREATE OR REPLACE FUNCTION peeps.person_in_table(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	status := 200;
	EXECUTE FORMAT ('
		SELECT row_to_json(r)
		FROM (
			SELECT id FROM %s WHERE person_id=%s
		) r', $2, $1
	) INTO js;
	IF js IS NULL THEN status := 404;
	js := '{}'; RETURN; END IF;

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
