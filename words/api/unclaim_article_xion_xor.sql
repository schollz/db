-- use to un-claim an article from a translator that has done just
-- one or two lines, long ago, and has clearly abandoned it.
-- PARAMS: translations.id, translators.id
CREATE OR REPLACE FUNCTION words.unclaim_article_xion_xor(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	article_id integer;
BEGIN
	article_id := words.article_for_xion($1);
	-- only one of these three updates will match, either translated_
	UPDATE words.translations
	SET translated_by = NULL, translated_at = NULL
	WHERE id IN (
		SELECT * FROM words.tids_for_article_xor(article_id, $2))
	AND translated_by = $2;
	-- .. or review1_
	UPDATE words.translations
	SET review1_by = NULL, review1_at = NULL
	WHERE id IN (
		SELECT * FROM words.tids_for_article_xor(article_id, $2))
	AND review1_by = $2;
	-- .. or review2_
	UPDATE words.translations
	SET review2_by = NULL, review2_at = NULL
	WHERE id IN (
		SELECT * FROM words.tids_for_article_xor(article_id, $2))
	AND review2_by = $2;
	-- .. or final_
	UPDATE words.translations
	SET final_by = NULL, final_at = NULL
	WHERE id IN (
		SELECT * FROM words.tids_for_article_xor(article_id, $2))
	AND final_by = $2;
	status := 200;
	js := '{}';
END;
$$ LANGUAGE plpgsql;
