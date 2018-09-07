-- translation.ids this translator can claim
-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.xor_claim(integer) RETURNS SETOF integer AS $$
	SELECT t.id
	FROM words.translators r
	JOIN words.coltranes c ON c.translator_id = r.id
	JOIN words.articles a ON a.collection_id = c.collection_id
	JOIN words.sentences s ON s.article_id = a.id
	JOIN words.translations t ON (t.sentence_code = s.code AND t.lang = r.lang)
	WHERE r.id = $1
	AND ((r.roll = 1 AND t.translated_by IS NULL)
		OR (r.roll = 2 AND t.translated_at IS NOT NULL AND t.review1_by IS NULL)
		OR (r.roll = 3 AND t.review1_at IS NOT NULL AND t.review2_by IS NULL)
		OR (r.roll = 9 AND t.final_by IS NULL))
	ORDER BY t.id;
$$ LANGUAGE SQL STABLE;
