--Route{
--  api = "peeps.add_url",
--  args = {"person_id", "url"},
--  method = "POST",
--  url = "/person/([0-9]+)/urls",
--  captures = {"person_id"},
--}
CREATE OR REPLACE FUNCTION peeps.add_url(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	WITH nu AS (
		INSERT INTO peeps.urls(person_id, url)
		VALUES ($1, $2)
		RETURNING *
	)
	SELECT row_to_json(r.*) INTO js FROM nu r;
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
