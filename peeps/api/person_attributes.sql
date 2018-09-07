-- *all* attribute keys, sorted, and if we have attributes for this person,
-- then those values are here, but returns null values for any not found
--Route{
--  api = "peeps.person_attributes",
--  args = {"id"},
--  method = "GET",
--  url = "/person/([0-9]+)/attributes",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.person_attributes(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := json_agg(r) FROM (
		SELECT atkey, plusminus
		FROM peeps.atkeys
			LEFT JOIN peeps.attributes ON (
				peeps.atkeys.atkey = peeps.attributes.attribute
				AND peeps.attributes.person_id = $1
			)
		ORDER BY peeps.atkeys.atkey
	) r;
	status := 200;
END;
$$ LANGUAGE plpgsql;
