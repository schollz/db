--Route{
--  api = "peeps.people_search",
--  args = {"q"},
--  method = "GET",
--  url = "/people/search",
--  params = {"q"},
--}
CREATE OR REPLACE FUNCTION peeps.people_search(text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	q text;
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	q := concat('%', btrim($1, E'\t\r\n '), '%');
	IF LENGTH(q) < 4 THEN
		RAISE 'search term too short';
	END IF;
	js := json_agg(r) FROM (
		SELECT *
		FROM peeps.people_view
		WHERE id IN (
			SELECT id
			FROM peeps.people
			WHERE name ILIKE q
			OR company ILIKE q
			OR email ILIKE q
		)
		ORDER BY email_count DESC, id DESC
	) r;
	status := 200;
	IF js IS NULL THEN js := '{}'; END IF;

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
