CREATE OR REPLACE FUNCTION words.get_xors(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT t.*,
			p.name,
			p.email,
			p.public_id
		FROM words.translators t
		LEFT JOIN peeps.people p ON t.person_id = p.id
		ORDER BY t.lang, t.roll, t.id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
