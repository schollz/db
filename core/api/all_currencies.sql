-- GET /currencies
-- PARAMS: -none-
-- RETURNS array of objects:
-- [{"code":"AUD","name":"Australian Dollar"},{"code":"BGN","name":"Bulgarian Lev"}... ]
CREATE OR REPLACE FUNCTION core.all_currencies(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (SELECT code::text, name FROM core.currencies ORDER BY code) r;
END;
$$ LANGUAGE plpgsql;
