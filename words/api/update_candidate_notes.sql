-- PARAMS: candidates.id, notes
CREATE OR REPLACE FUNCTION words.update_candidate_notes(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE words.candidates SET notes = $2 WHERE id = $1;
	status := 200;
	js := json_build_object('id', $1);
END;
$$ LANGUAGE plpgsql;
