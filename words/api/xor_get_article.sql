-- PARAMS: translators.id, articles.id
CREATE OR REPLACE FUNCTION words.xor_get_article(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	role smallint;
	tlang char(2);
BEGIN
	role := words.xor_article_role($1, $2);
	IF role IS NULL THEN
		status := 404;
		js := '{}';
		RETURN;
	END IF;
	SELECT lang INTO tlang FROM words.translators WHERE id = $1;
	status := 200;
	js := row_to_json(r) FROM (
		SELECT id,
			role,
			words.xor_article_state($1, $2) AS state,
			filename,
			template,
			raw,
			words.merge_article($2, tlang) AS merged, (
			SELECT json_agg(ss) AS sentences FROM (
				SELECT t.id, (CASE
					WHEN role = 1 THEN translated_at
					WHEN role = 2 THEN review1_at
					WHEN role = 3 THEN review2_at
					WHEN role = 9 THEN final_at END) AS done_at,
					t.translated_by,
					t.translated_at,
					t.review1_by,
					t.review1_at,
					t.review2_by,
					t.review2_at,
					t.final_by,
					t.final_at,
					s.sortid,
					s.code,
					s.replacements,
					s.comment,
					s.sentence,
					t.translation AS raw,
					words.merge_replacements(translation, replacements) AS merged
				FROM words.sentences s
				JOIN words.translations t
					ON (s.code = t.sentence_code AND t.lang = tlang)
				WHERE s.article_id = $2
				ORDER BY s.sortid
			) ss)
		FROM words.articles
		WHERE id = $2
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;
