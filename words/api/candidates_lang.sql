CREATE OR REPLACE FUNCTION words.candidates_lang(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT c.*, p.name
		FROM words.candidates c
		JOIN peeps.people p ON c.person_id = p.id
		WHERE lang = $1
		AND has_emailed IS TRUE
		ORDER BY c.yesno DESC, c.lang ASC, c.role ASC, c.expert DESC, c.id ASC
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
