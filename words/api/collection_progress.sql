-- PARAMS: collections.id
-- returns lang t_done t_claim r1_done r1_claim r2_done r2_claim
CREATE OR REPLACE FUNCTION words.collection_progress(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		WITH tx AS (
			SELECT lang,
				translated_by, translated_at,
				review1_by, review1_at,
				review2_by, review2_at,
				final_by, final_at
			FROM words.translations
			WHERE sentence_code IN (
				SELECT code FROM words.sentences
				WHERE article_id IN (
					SELECT id FROM words.articles
					WHERE collection_id = $1))
		)
		SELECT y.lang,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND translated_at IS NOT NULL) AS t_done,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND translated_by IS NOT NULL) AS t_claim,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND review1_at IS NOT NULL) AS r1_done,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND review1_by IS NOT NULL) AS r1_claim,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND review2_at IS NOT NULL) AS r2_done,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND review2_by IS NOT NULL) AS r2_claim,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND final_at IS NOT NULL) AS f_done,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND final_by IS NOT NULL) AS f_claim
		FROM tx y
		GROUP BY y.lang
		ORDER BY t_done DESC, r1_done DESC, r2_done DESC, f_done DESC, lang ASC
	) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;
