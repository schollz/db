-- list of articles grouped for translator
-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.xor_articles(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	rol smallint;
BEGIN
	SELECT roll INTO rol FROM words.translators WHERE id = $1;
	IF rol = 9 THEN
		js := json_build_object(
		'do', (
			SELECT json_agg(d1) FROM (
				SELECT a.id, a.filename
				FROM words.chapters c
				JOIN words.articles a ON c.article_id = a.id
				WHERE a.id IN (
					SELECT * FROM words.articles_xor_state($1, 'do')
				) ORDER BY c.sortid
			) d1),
		'done', (
			SELECT json_agg(d2) FROM (
				SELECT a.id, a.filename
				FROM words.chapters c
				JOIN words.articles a ON c.article_id = a.id
				WHERE a.id IN (
					SELECT * FROM words.articles_xor_state($1, 'done')
				) ORDER BY c.sortid
			) d2)
		);
	ELSE
		js := json_build_object(
		'do', (
			SELECT json_agg(a) FROM (
				SELECT id, filename FROM words.articles WHERE id IN (
					SELECT * FROM words.articles_xor_state($1, 'do')
				) ORDER BY id
			) a),
		'claim', (
			SELECT json_agg(b) FROM (
				SELECT id, filename FROM words.articles WHERE id IN (
					SELECT * FROM words.articles_xor_state($1, 'claim')
				) ORDER BY RANDOM()
			) b),
		'wait', (
			SELECT json_agg(b) FROM (
				SELECT id, filename FROM words.articles WHERE id IN (
					SELECT * FROM words.articles_xor_state($1, 'wait')
				) ORDER BY RANDOM()
			) b),
		'done', (
			SELECT json_agg(c) FROM (
				SELECT id, filename FROM words.articles WHERE id IN (
					SELECT * FROM words.articles_xor_state($1, 'done')
				) ORDER BY id DESC
			) c)
		);
	END IF;
	status := 200;
END;
$$ LANGUAGE plpgsql;
