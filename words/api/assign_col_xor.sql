-- assign collection to translator 
-- PARAMS: collections.id, translators.id
CREATE OR REPLACE FUNCTION words.assign_col_xor(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	-- if not found, add this collection-translator link
	PERFORM 1
	FROM words.coltranes
	WHERE collection_id = $1
	AND translator_id = $2;
	IF NOT FOUND THEN
		INSERT INTO words.coltranes(collection_id, translator_id)
		VALUES ($1, $2);
	END IF;
	status := 200;
	-- make sure collection has this translator's languages
	-- return translations.ids
	js := json_agg(r) FROM (
		SELECT id
		FROM words.init_collection_lang($1, (
				SELECT lang
				FROM words.translators
				WHERE id = $2
		)) id
	) r;
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
