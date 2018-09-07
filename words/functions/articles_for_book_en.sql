-- PARAMS: books.id but ONLY for my original English version
CREATE OR REPLACE FUNCTION words.articles_for_book_en(integer,
	OUT sortid smallint, OUT title text, OUT body text)
RETURNS SETOF record AS $$
	SELECT c.sortid,
		s.sentence as title,
		words.merge_article(c.article_id, 'en') AS body
	FROM words.books b
	JOIN words.chapters c ON b.metabook_id = c.metabook_id
	JOIN words.sentences s ON c.title = s.code
	WHERE b.id = $1 AND b.lang = 'en'
	ORDER BY c.sortid;
$$ LANGUAGE sql;
