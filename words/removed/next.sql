-- PARAMS: translations.id
-- RETURNS: next translation_id in sequence after this. NULL if none
CREATE OR REPLACE FUNCTION words.next_xion(integer, OUT xion_id integer) AS $$
DECLARE
	next_code char(8);
BEGIN
	-- first see if there's a next code
	SELECT code INTO next_code
	FROM words.sentences
	WHERE article_id = words.article_for_xion($1)
	AND sortid > (
		SELECT sortid
		FROM words.sentences
		WHERE code = (
			SELECT sentence_code
			FROM words.translations
			WHERE id = $1
		)
	)
	ORDER BY sortid
	LIMIT 1;
	-- if not, return NULL
	IF next_code IS NULL THEN
		xion_id := NULL;
	ELSE
		-- if so, use code + existing lang to find next translation
		SELECT id INTO xion_id
		FROM words.translations
		WHERE sentence_code = next_code
		AND lang = (
			SELECT lang
			FROM words.translations
			WHERE id = $1
		);
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: translations.id
-- for router to send translator to article and translation if this one was successful
CREATE OR REPLACE FUNCTION words.next_if_good(integer,
	OUT article_id smallint, OUT xion_id integer) AS $$
BEGIN
	SELECT x.* INTO article_id FROM words.article_for_xion($1) x;
	SELECT y.* INTO xion_id FROM words.next_xion($1) y;
END;
$$ LANGUAGE plpgsql;


