-- PARAMS: translators.id, metabooks.id
CREATE OR REPLACE FUNCTION words.assign_editor(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE words.translations
	SET final_by = $1
	WHERE sentence_code IN (
		SELECT code
		FROM words.sentences
		WHERE article_id IN (
			SELECT article_id
			FROM words.chapters
			WHERE metabook_id = $2))
	AND lang = (
		SELECT lang
		FROM words.translators
		WHERE id = $1)
	AND final_by IS NULL;
	status := 200;
	js := json_agg(r) FROM (
		SELECT id
		FROM words.translations
		WHERE final_by = $1
		ORDER BY id) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;
