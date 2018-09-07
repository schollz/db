--Route{
--  api = "peeps.person_set_attribute",
--  args = {"id", "attribute", "true"},
--  method = "PUT",
--  url = "/person/([0-9]+)/attributes/([a-z-]+)/plus",
--  captures = {"id", "attribute"},
--}
CREATE OR REPLACE FUNCTION peeps.person_set_attribute(integer, text, boolean,
	OUT status smallint, OUT js json) AS $$
DECLARE
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE peeps.attributes
	SET plusminus = $3
	WHERE person_id = $1
	AND attribute = $2;
	IF NOT FOUND THEN
		INSERT INTO peeps.attributes VALUES ($1, $2, $3);
	END IF;
	SELECT x.status, x.js INTO status, js FROM peeps.person_attributes($1) x;

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
