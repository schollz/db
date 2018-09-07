CREATE OR REPLACE FUNCTION words.mismatched_tags(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id, code, sentence, translation, lang, translated_by, review1_by FROM (
			SELECT t.id, t.lang, translation, translated_by, review1_by,
			(SELECT COUNT(*) FROM regexp_matches(translation, E'[<>]', 'g')) AS tx,
			s.code, sentence,
			(SELECT COUNT(*) FROM regexp_matches(sentence, E'[<>]', 'g')) AS sx
			FROM words.translations t
			JOIN words.sentences s ON t.sentence_code=s.code
			WHERE translation IS NOT NULL
			AND (sentence LIKE '%<%' OR sentence LIKE '%>%')
			AND t.id > 5000
		) tt
		WHERE tx != sx
		ORDER BY id) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
