-- PARAMS: translator_id, translation_id
CREATE OR REPLACE FUNCTION words.xor_unfinish_xion(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	role smallint;
BEGIN
	role := words.xor_xion_role($1, $2);
	-- stop unless translator has permission for this translation
	IF role IS NULL THEN
		status := 403;
		js := '{"error":"not yours"}';
		RETURN;
	END IF;
	-- pick which field to mark based on their role
	CASE role
		WHEN 1 THEN
			UPDATE words.translations
			SET translated_at = NULL
			WHERE id = $2;
		WHEN 2 THEN
			UPDATE words.translations
			SET review1_at = NULL
			WHERE id = $2;
		WHEN 3 THEN
			UPDATE words.translations
			SET review2_at = NULL
			WHERE id = $2;
	END CASE;
	SELECT x.status, x.js INTO status, js
	FROM words.get_xion($2) x;
END;
$$ LANGUAGE plpgsql;
