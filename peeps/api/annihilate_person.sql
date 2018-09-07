--Route{
--  api = "peeps.annihilate_person",
--  args = {"person_id"},
--  method = "DELETE",
--  url = "/person/([0-9]+)/annihilate",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.annihilate_person(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	res RECORD;
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	js := row_to_json(r.*) FROM peeps.person_view r WHERE id = $1;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; RETURN; END IF;
	FOR res IN SELECT * FROM core.tables_referencing('peeps', 'people', 'id') LOOP
		EXECUTE format ('DELETE FROM %s WHERE %I=%s',
			res.tablename, res.colname, $1);
	END LOOP;
	DELETE FROM peeps.people WHERE id = $1;

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
