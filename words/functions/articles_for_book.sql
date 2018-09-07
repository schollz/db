-- PARAMS: books.id
CREATE OR REPLACE FUNCTION words.articles_for_book(integer,
	OUT sortid smallint,
	OUT translator_id smallint, OUT translator_name varchar(127),
	OUT review1_id smallint, OUT review1_name varchar(127),
	OUT review2_id smallint, OUT review2_name varchar(127),
	OUT final_id smallint, OUT final_name varchar(127),
	OUT title text, OUT body text)
RETURNS SETOF record AS $$
	SELECT c.sortid,
		t.translated_by AS translator_id,
		p0.name AS translator_name,
		t.review1_by AS review1_id,
		p1.name AS review1_name,
		t.review2_by AS review2_id,
		p2.name AS review2_name,
		t.final_by AS final_id,
		pf.name AS final_name,
		t.translation AS title,
		words.merge_article(c.article_id, b.lang) AS body
	FROM words.books b
	JOIN words.chapters c ON b.metabook_id = c.metabook_id
	JOIN words.translations t
		ON (c.title = t.sentence_code AND t.lang = b.lang)
	LEFT JOIN words.translators r0 ON t.translated_by = r0.id
	LEFT JOIN peeps.people p0 ON r0.person_id = p0.id
	LEFT JOIN words.translators r1 ON t.review1_by = r1.id
	LEFT JOIN peeps.people p1 ON r1.person_id = p1.id
	LEFT JOIN words.translators r2 ON t.review2_by = r2.id
	LEFT JOIN peeps.people p2 ON r2.person_id = p2.id
	LEFT JOIN words.translators rf ON t.final_by = rf.id
	LEFT JOIN peeps.people pf ON rf.person_id = pf.id
	WHERE b.id = $1
	ORDER BY c.sortid;
$$ LANGUAGE sql;
