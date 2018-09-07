-- PARAMS: pairing.id, tag text
-- Adds that tag to both concepts in the pair
--Route{
-- api = "lat.tag_pairing",
-- args = {"id", "tag"},
-- method = "POST",
-- url = "/pairings/([0-9]+)/tags",
-- captures = {"id"},
-- params = {"tag"},
--}
CREATE OR REPLACE FUNCTION lat.tag_pairing(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	id1 integer;
	id2 integer;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	SELECT concept1_id, concept2_id INTO id1, id2
	FROM lat.pairings
	WHERE id = $1;
	PERFORM lat.tag_concept(id1, $2);
	PERFORM lat.tag_concept(id2, $2);
	SELECT x.status, x.js INTO status, js FROM lat.get_pairing($1) x;

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
