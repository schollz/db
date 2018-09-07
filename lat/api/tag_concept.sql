--Route{
-- api = "lat.tag_concept",
-- args = {"id", "tag"},
-- method = "POST",
-- url = "/concepts/([0-9]+)/tags",
-- captures = {"id"},
-- params = {"tag"},
--}
CREATE OR REPLACE FUNCTION lat.tag_concept(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	cid integer;
	tid integer;
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	SELECT id INTO cid
	FROM lat.concepts
	WHERE id = $1;
	IF NOT FOUND THEN 
	status := 404;
	js := '{}';
 RETURN; END IF;
	SELECT id INTO tid
	FROM lat.tags
	WHERE tag = lower(btrim(regexp_replace($2, '\s+', ' ', 'g')));
	IF tid IS NULL THEN
		INSERT INTO lat.tags (tag)
		VALUES ($2)
		RETURNING id INTO tid;
	END IF;
	SELECT concept_id INTO cid
		FROM lat.concepts_tags
		WHERE concept_id = $1
		AND tag_id = tid;
	IF NOT FOUND THEN
		INSERT INTO lat.concepts_tags(concept_id, tag_id) VALUES ($1, tid);
	END IF;
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

