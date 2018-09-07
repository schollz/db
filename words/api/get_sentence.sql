-- PARAMS: code
CREATE OR REPLACE FUNCTION words.get_sentence(char(8),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT s.code,
			s.article_id,
			a.filename,
			s.sortid,
			s.sentence,
			s.replacements,
			s.comment, (
				SELECT json_agg(tt) AS translations
				FROM (
					SELECT t.id, lang, translation
					FROM words.translations t
					WHERE t.sentence_code = s.code
					ORDER BY t.id
				) tt
			)
		FROM words.sentences s
		JOIN words.articles a ON s.article_id = a.id
		WHERE s.code = $1
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;
