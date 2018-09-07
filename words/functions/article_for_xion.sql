-- PARAMS: translations.id
-- RETURNS: article_id
CREATE OR REPLACE FUNCTION words.article_for_xion(integer) RETURNS smallint AS $$
	SELECT s.article_id
	FROM words.translations t
	JOIN words.sentences s ON t.sentence_code = s.code
	WHERE t.id = $1;
$$ LANGUAGE SQL STABLE;
