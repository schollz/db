-- Get the entire translated text for this article, merged into template
-- PARAMS: articles.id, 2-char lang code
CREATE OR REPLACE FUNCTION words.merge_article(integer, char(2), OUT merged text) AS $$
DECLARE
	a RECORD;
BEGIN
	SELECT template INTO merged
	FROM words.articles
	WHERE id = $1;
	-- if English, get from sentences.sentence, not translations.translation
	IF $2 = 'en' THEN
		FOR a IN
			SELECT code,
				words.merge_replacements(sentence, replacements) AS txn
			FROM words.sentences
			WHERE article_id = $1
			ORDER BY sortid
			LOOP
				merged := replace(merged, '{' || a.code || '}', COALESCE(a.txn, ''));
			END LOOP;
	ELSE
		FOR a IN
			SELECT code,
				words.merge_replacements(translation, replacements) AS txn
			FROM words.sentences s
			JOIN words.translations t ON s.code = t.sentence_code
			WHERE article_id = $1
			AND lang = $2
			ORDER BY s.sortid
			LOOP
				merged := replace(merged, '{' || a.code || '}', COALESCE(a.txn, ''));
			END LOOP;
	END IF;
END;
$$ LANGUAGE plpgsql;
