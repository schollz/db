-- PARAMS: translator_id, translation_id, text
CREATE OR REPLACE FUNCTION words.xor_update_xion(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	role smallint;
	old_translation text;
BEGIN
	role := words.xor_xion_role($1, $2);
	-- stop unless translator has permission for this translation
	IF role IS NULL THEN
		status := 403;
		js := '{"error":"not yours"}';
		RETURN;
	END IF;
	-- if their role _at is not null, no more changes (see "unfinish" action)
	CASE role
		WHEN 1 THEN
			PERFORM 1 FROM words.translations
			WHERE id = $2 AND translated_at IS NOT NULL;
		WHEN 2 THEN
			PERFORM 1 FROM words.translations
			WHERE id = $2 AND review1_at IS NOT NULL;
		WHEN 3 THEN
			PERFORM 1 FROM words.translations
			WHERE id = $2 AND review2_at IS NOT NULL;
	END CASE;
	IF FOUND THEN  -- from query inside CASE role
		status := 403;
		js := '{"error":"no update: finished"}';
		RETURN;
	END IF;
	-- if translated_at is not null, then save what we are replacing
	SELECT translation INTO old_translation
	FROM words.translations
	WHERE id = $2
	AND translated_at IS NOT NULL;
	-- ... but only if new translation is different than old one
	IF FOUND AND old_translation != $3 THEN
		INSERT INTO words.replaced
			(translation_id, replaced_by, translation)
		SELECT id, $1, translation
		FROM words.translations
		WHERE id = $2;
	END IF;
	UPDATE words.translations
	SET translation = $3
	WHERE id = $2;
	SELECT x.status, x.js INTO status, js
	FROM words.get_xion($2) x;
EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);
END;
$$ LANGUAGE plpgsql;
