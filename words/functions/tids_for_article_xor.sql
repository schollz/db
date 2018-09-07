-- get translation.ids for this article for this translator's language
-- PARAMS: articles.id, translators.id
CREATE OR REPLACE FUNCTION words.tids_for_article_xor(integer, integer) RETURNS SETOF integer AS $$
	SELECT t.id
	FROM words.translations t
	JOIN words.sentences s ON t.sentence_code = s.code
	JOIN words.translators r ON r.id = $2 
	WHERE s.article_id = $1
	AND t.lang = r.lang
	ORDER BY t.id;
$$ LANGUAGE SQL STABLE;
