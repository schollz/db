-- TODO: fixtures and tests
CREATE OR REPLACE FUNCTION peeps.get_accesskey_formletters(
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT accesskey, title, body
		FROM peeps.formletters
		WHERE accesskey IS NOT NULL
		ORDER BY accesskey
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;
