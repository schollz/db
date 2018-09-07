--Route{
-- api = "lat.add_url",
-- args = {"concept_id", "url", "notes"},
-- method = "POST",
-- url = "/concepts/([0-9]+)/urls",
-- captures = {"concept_id"},
-- params = {"url", "notes"},
--}
CREATE OR REPLACE FUNCTION lat.add_url(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	uid integer;

	err_code text;
	err_msg text;
	err_detail text;
	err_context text;

BEGIN
	INSERT INTO lat.urls (url, notes)
	VALUES ($2, $3)
	RETURNING id INTO uid;
	INSERT INTO lat.concepts_urls (concept_id, url_id)
	VALUES ($1, uid);
	SELECT x.status, x.js INTO status, js FROM lat.get_url(uid) x;

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

