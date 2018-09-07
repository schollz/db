-- PARAMS: candidates.id
CREATE OR REPLACE FUNCTION words.delete_candidate(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	DELETE FROM words.candidates
	WHERE id = $1
	RETURNING person_id INTO pid;
	status := 200;
	js := json_build_object('person_id', pid);
END;
$$ LANGUAGE plpgsql;
