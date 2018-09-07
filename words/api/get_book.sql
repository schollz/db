-- PARAMS: books.id
-- id, metabook_id, lang, title, subtitle, chapters: [{num, title, body}]
CREATE OR REPLACE FUNCTION words.get_book(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	whatlang char(2);
BEGIN
	SELECT lang INTO whatlang FROM words.books WHERE id = $1;
	IF whatlang = 'en' THEN
		js := row_to_json(r) FROM (
			SELECT id, metabook_id, lang, title, subtitle,
			(SELECT json_agg(ch) AS chapters FROM (
				SELECT c.sortid AS num,
					s.sentence AS title,
					a.raw AS body
				FROM words.books b
				JOIN words.chapters c ON b.metabook_id = c.metabook_id
				JOIN words.articles a ON c.article_id = a.id
				JOIN words.sentences s ON c.title = s.code
				WHERE b.id = $1
				AND c.sortid IS NOT NULL
				ORDER BY c.sortid
			) ch)
			FROM words.books
			WHERE id = $1
		) r;
	ELSE
		js := row_to_json(r) FROM (
			SELECT id, metabook_id, lang, title, subtitle,
			(SELECT json_agg(ch) AS chapters FROM (
				SELECT c.sortid AS num,
					t.translation AS title,
					words.merge_article(c.article_id, b.lang) AS body
				FROM words.books b
				JOIN words.chapters c ON b.metabook_id = c.metabook_id
				JOIN words.translations t
					ON (c.title = t.sentence_code AND t.lang = b.lang)
				WHERE b.id = $1
				AND c.sortid IS NOT NULL
				ORDER BY c.sortid
			) ch)
			FROM words.books
			WHERE id = $1
		) r;
	END IF;
	IF js IS NULL THEN js := '[]'; END IF;
	status := 200;
END;
$$ LANGUAGE plpgsql;
