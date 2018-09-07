-- PARAMS: articles.id
CREATE OR REPLACE FUNCTION words.get_article(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT a.id,
			a.filename,
			json_build_object('id', c.id, 'name', c.name) AS collection,
			a.raw,
			a.template,
			(SELECT json_agg(ss) AS sentences FROM (
				SELECT code, sortid, sentence, replacements, comment
				FROM words.sentences
				WHERE article_id = a.id
				ORDER BY sortid
			) ss)
		FROM words.articles a
		JOIN words.collections c ON a.collection_id = c.id
		WHERE a.id = $1
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;
