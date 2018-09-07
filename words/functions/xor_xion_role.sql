-- returns smallint (1/2/3) : their role in this translation (NULL = not assigned)
-- PARAMS: translators.id, translations.id
CREATE OR REPLACE FUNCTION words.xor_xion_role(integer, integer) RETURNS smallint AS $$
	SELECT r.roll
	FROM words.coltranes c
	LEFT JOIN words.translators r ON c.translator_id = r.id
	JOIN words.articles a ON a.collection_id = c.collection_id
	JOIN words.sentences s ON s.article_id = a.id
	JOIN words.translations t
		ON (t.sentence_code = s.code AND t.lang = r.lang)
	WHERE c.translator_id = $1
	AND t.id = $2;
$$ LANGUAGE SQL STABLE;
