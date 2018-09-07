------------------------------------------------
-------------------------------------- JSON API:
------------------------------------------------ 

-- 'do' => 8, 'doing' => 1, 'done' => 41
-- PARAMS: translator_id
CREATE OR REPLACE FUNCTION words.article_state_count_for(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT stat, COUNT(*) AS howmany
		FROM words.translator_art_state($1)
		GROUP BY stat
		ORDER BY stat
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: translators.id
-- OUT: [{article_id:1, stat:doing},{article_id:2, stat:done}]
CREATE OR REPLACE FUNCTION words.translator_art_stat(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT article_id, stat
		FROM words.translator_art_state($1)
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: translators.id
-- OUT: [{stat:doing, howmany:2},{stat:done, howmany:4}]
CREATE OR REPLACE FUNCTION words.translator_art_stat_count(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT stat,
		COUNT(article_id) AS howmany
		FROM words.translator_art_state($1)
		GROUP BY stat
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: translators.id, state(doing|do|done)
-- OUT: [{article_id:1, filename:'whatver'},{article_id:2, filename:'yeahthis'}]
CREATE OR REPLACE FUNCTION words.translator_art_with_stat(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT article_id, filename
		FROM words.translator_art_state($1) tas
		JOIN words.articles
			ON tas.article_id=articles.id
		WHERE stat = $2
		ORDER BY article_id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: translators.id, state(new|review|done|wait)
-- OUT: 
CREATE OR REPLACE FUNCTION words.translator_ons_with_stat(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT t.id, sentence_code, lang, state, s.sentence, translation
		FROM words.translations t
		JOIN words.sentences s
			ON t.sentence_code = s.code
		WHERE lang = (
			SELECT lang
			FROM words.translators
			WHERE id = $1
		)
		AND state = $2
		AND sentence_code IN (
			SELECT code
			FROM words.sentences
			WHERE article_id IN (
				SELECT article_id
				FROM words.articles_translators
				WHERE translator_id = $1
			)
		)
		ORDER BY t.id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: article_id, lang
CREATE OR REPLACE FUNCTION words.article_paired_lang(integer, char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	-- NOTE: DUPLICATED this query in translator_get_article
	js := json_agg(r) FROM (
		SELECT t.id,
			t.state,
			s.code,
			s.sentence,
			words.merge_replacements(s.sentence, s.replacements) AS s2,
			t.translation,
			words.merge_replacements(t.translation, s.replacements) AS t2,
			s.comment,
			t.question
		FROM words.sentences s
		LEFT JOIN words.translations t
			ON s.code=t.sentence_code
		WHERE t.lang = $2
		AND s.article_id = $1
		ORDER BY s.sortid
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;



-- PARAMS: translator_id, article_id
-- checks for auth, gets translator.lang, uses above if OK
CREATE OR REPLACE FUNCTION words.translator_article_paired(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	tlang char(2);
BEGIN
	-- if this translator has been assigned this article, set tlang
	SELECT t.lang INTO tlang
	FROM words.articles_translators a
	LEFT JOIN words.translators t
		ON a.translator_id = t.id
	WHERE a.translator_id = $1
	AND a.article_id = $2;
	-- ... so if no tlang, then translator was not assigned article
	IF tlang IS NULL THEN
		status := 403;
		js := '{"not":"yours"}';
	ELSE
		SELECT x.status, x.js
		INTO status, js
		FROM words.article_paired_lang($2, tlang) x;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: translators.id, articles.id
-- TODO: replace translator_article_paired with this
CREATE OR REPLACE FUNCTION words.translator_get_article(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	tlang char(2);
	trole char(3);
BEGIN
	-- if this translator has been assigned this article, set tlang
	SELECT t.lang, t.role INTO tlang, trole
	FROM words.articles_translators a
	LEFT JOIN words.translators t
		ON a.translator_id = t.id
	WHERE a.translator_id = $1
	AND a.article_id = $2;
	-- ... so if no tlang, then translator was not assigned article
	IF tlang IS NULL THEN
		status := 403;
		js := '{"not":"yours"}';
	ELSE
		status := 200;
		-- filename, state, lines
		js := row_to_json(r) FROM (
			SELECT a.id,
			a.filename,
			words.role_state(trole, words.article_state($2, tlang)) AS state,
			(SELECT json_agg(u) AS lines FROM (
				SELECT t.id,
					t.state,
					s.code,
					s.sentence,
					words.merge_replacements(s.sentence, s.replacements) AS s2,
					t.translation,
					words.merge_replacements(t.translation, s.replacements) AS t2,
					words.tags_match_replacements(t.translation, s.replacements) AS tags_match,
					s.comment,
					t.question
				FROM words.sentences s
				LEFT JOIN words.translations t
					ON s.code=t.sentence_code
				WHERE t.lang = tlang
				AND s.article_id = $2
				ORDER BY s.sortid) u)
			FROM words.articles a
			WHERE a.id = $2
		) r;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- next sentence not done yet
-- PARAMS: article_id, lang
CREATE OR REPLACE FUNCTION words.next_sentence_for_article_lang(integer, char(2),
	OUT status smallint, OUT js json) AS $$
DECLARE
	code1 char(8);
BEGIN
	SELECT code INTO code1
	FROM words.sentences
	JOIN words.translations
		ON sentences.code = translations.sentence_code
	WHERE article_id = $1
	AND lang = $2
	AND translation IS NULL
	ORDER BY id
	LIMIT 1;
	IF code1 IS NULL THEN m4_NOTFOUND ELSE
		SELECT x.status, x.js INTO status, js
		FROM words.get_sentence_lang(code1, $2) x;
	END IF;
END;
$$ LANGUAGE plpgsql;


