-- creates empty translations if none exist for all the sentences in this collection
-- returns list of translation.ids 
-- PARAMS: collections.id, lang
CREATE OR REPLACE FUNCTION words.init_collection_lang(integer, char(2)) RETURNS SETOF integer AS $$
BEGIN
	-- do query first just to see if exists
	PERFORM t.id
	FROM words.translations t
	JOIN words.sentences s ON t.sentence_code = s.code
	JOIN words.articles a ON s.article_id = a.id
	WHERE a.collection_id = $1
	AND t.lang = $2 LIMIT 1;
	IF NOT FOUND THEN
		-- insert if none
		INSERT INTO words.translations(sentence_code, lang)
			SELECT code, $2 AS lang
			FROM words.sentences s
			JOIN words.articles a ON s.article_id = a.id
			WHERE a.collection_id = $1
			ORDER BY a.id, s.sortid;
	END IF;
	-- now return translation.ids
	RETURN QUERY SELECT t.id
	FROM words.translations t
	JOIN words.sentences s ON t.sentence_code = s.code
	JOIN words.articles a ON s.article_id = a.id
	WHERE a.collection_id = $1
	AND t.lang = $2
	ORDER BY t.id;
END;
$$ LANGUAGE plpgsql;
