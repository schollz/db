-- GET /currency_names
-- PARAMS: -none-
-- RETURNS single code:name object:
-- {"AUD":"Australian Dollar", "BGN":"Bulgarian Lev", ...}
CREATE OR REPLACE FUNCTION core.currency_names(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_object(
		ARRAY(SELECT code::text FROM core.currencies ORDER BY code),
		ARRAY(SELECT name FROM core.currencies ORDER BY code));
END;
$$ LANGUAGE plpgsql;

