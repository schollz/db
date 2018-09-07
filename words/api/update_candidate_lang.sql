-- PARAMS: candidates.id, lang
CREATE OR REPLACE FUNCTION words.update_candidate_lang(integer, char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE words.candidates SET lang = $2 WHERE id = $1;
	status := 200;
	js := json_build_object('id', $1);
END;
$$ LANGUAGE plpgsql;
