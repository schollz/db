-- Full complete representation of an article, with all parts that might be used to edit.
-- id, filename, template, raw, merged, sentences: [{sortid, code, replacements, raw, merged}]
-- PARAMS: article_id, lang
CREATE OR REPLACE FUNCTION words.get_article_lang(integer, char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	-- English comes directly from sentences.sentence not translations.translation
	IF $2 = 'en' THEN js := row_to_json(r) FROM (
		SELECT id,
			filename,
			template,
			raw,
			words.merge_article($1, $2) AS merged, (
			SELECT json_agg(s) AS sentences FROM (
				SELECT sortid,
					code,
					replacements,
					sentence AS raw,
					words.merge_replacements(sentence, replacements) AS merged
				FROM words.sentences 
				WHERE article_id = $1
				ORDER BY sortid
			) s)
		FROM words.articles
		WHERE id = $1
	) r;
	-- Everything but English is in translations table
	ELSE js := row_to_json(r) FROM (
		SELECT id,
			filename,
			template,
			raw,
			words.merge_article($1, $2) AS merged, (
			SELECT json_agg(s) AS sentences FROM (
				SELECT t.id,
					s.sortid,
					s.code,
					s.replacements,
					t.translation AS raw,
					words.merge_replacements(translation, replacements) AS merged
				FROM words.sentences s
				JOIN words.translations t
					ON (s.code = t.sentence_code AND t.lang = $2)
				WHERE s.article_id = $1
				ORDER BY s.sortid
			) s)
		FROM words.articles
		WHERE id = $1
	) r;
	END IF;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;
