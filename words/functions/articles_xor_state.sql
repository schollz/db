-- articles.ids with state: 'do', 'claim', 'wait', 'done'
-- PARAMS: translators.id, 'do|claim|done'
CREATE OR REPLACE FUNCTION words.articles_xor_state(integer, text) RETURNS SETOF smallint AS $$
BEGIN
	CASE $2
		WHEN 'claim' THEN -- if any translations can be "claim"ed then article can
			RETURN QUERY SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_claim($1));
		WHEN 'do' THEN -- if any translations are "do" then article is "do", unless "wait"
			RETURN QUERY SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_do($1))
			EXCEPT
			SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_wait($1));
		WHEN 'wait' THEN -- if any translations are "wait" then article is "wait"
			RETURN QUERY SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_wait($1));
		WHEN 'done' THEN -- done minus do = completely done
			RETURN QUERY SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_done($1))
			EXCEPT
			SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_do($1));
	END CASE;
END;
$$ LANGUAGE plpgsql;
