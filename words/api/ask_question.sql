-- PARAMS: translator_id, translation_id, question
CREATE OR REPLACE FUNCTION words.ask_question(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	-- stop unless translator has permission for this translation
	IF words.xor_xion_role($1, $2) IS NULL THEN
		status := 403;
		js := '{"error":"not yours"}';
	ELSE
		INSERT INTO words.questions
			(translation_id, asked_by, question)
		VALUES ($2, $1, $3);
		status := 200;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;
