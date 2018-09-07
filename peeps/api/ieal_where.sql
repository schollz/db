-- Array of people's [[id, email, address, lopass]] for emailing
-- PARAMS: key,val to be used in WHERE _key_ = _val_
--Route{
--  api = "peeps.ieal_where",
--  args = {"k", "v"},
--  method = "GET",
--  url = "/list/([a-z_]+)/(.+)",
--  captures = {"k", "v"},
--}
CREATE OR REPLACE FUNCTION peeps.ieal_where(text, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	EXECUTE format ('
		SELECT json_agg(j)
		FROM (
			SELECT json_build_array(id, email, address, lopass) AS j
			FROM peeps.people
			WHERE email IS NOT NULL
			AND %I = %L
			ORDER BY id
		) r', $1, $2
	) INTO js;
	status := 200;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
