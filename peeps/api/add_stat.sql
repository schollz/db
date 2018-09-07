--Route{
--  api = "peeps.add_stat",
--  args = {"person_id", "name", "value"},
--  method = "POST",
--  url = "/person/([0-9]+)/stats",
--  captures = {"person_id"},
--  params = {"name", "value"},
--}
CREATE OR REPLACE FUNCTION peeps.add_stat(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	WITH nu AS (
		INSERT INTO peeps.stats(person_id, statkey, statvalue)
		VALUES ($1, $2, $3)
		RETURNING *
	)
	SELECT row_to_json(r) INTO js FROM (
		SELECT id, created_at, statkey AS name, statvalue AS value FROM nu
	) r;
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
