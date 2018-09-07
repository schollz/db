-- returns smallint (1/2/3) : their role in this article (NULL = not assigned)
-- PARAMS: translators.id, articles.id
CREATE OR REPLACE FUNCTION words.xor_article_role(integer, integer) RETURNS smallint AS $$
	SELECT r.roll
	FROM words.coltranes c
	JOIN words.articles a ON a.collection_id = c.collection_id
	LEFT JOIN words.translators r ON c.translator_id = r.id
	WHERE c.translator_id = $1
	AND a.id = $2;
$$ LANGUAGE SQL STABLE;
