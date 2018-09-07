-- PARAMS: translation_id
CREATE OR REPLACE FUNCTION words.get_xion(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r) FROM (
		SELECT t.id,
		s.article_id,
		a.filename,
		t.sentence_code,
		t.lang,
		s.sentence,
		words.merge_replacements(s.sentence, s.replacements) AS s2,
		t.translation,
		words.merge_replacements(t.translation, s.replacements) AS t2,
		t.translated_at, (
			SELECT row_to_json(tr) AS translator FROM (
				SELECT r.id,
				r.person_id,
				p.name
				FROM words.translators r
				JOIN peeps.people p ON r.person_id = p.id
				WHERE r.id = t.translated_by
			) tr),
		t.review1_at, (
			SELECT row_to_json(r1) AS reviewer1 FROM (
				SELECT r.id,
				r.person_id,
				p.name
				FROM words.translators r
				JOIN peeps.people p ON r.person_id = p.id
				WHERE r.id = t.review1_by
			) r1),
		t.review2_at, (
			SELECT row_to_json(r2) AS reviewer2 FROM (
				SELECT r.id,
				r.person_id,
				p.name
				FROM words.translators r
				JOIN peeps.people p ON r.person_id = p.id
				WHERE r.id = t.review2_by
			) r2),
		t.final_at, (
			SELECT row_to_json(f) AS editor FROM (
				SELECT r.id,
				r.person_id,
				p.name
				FROM words.translators r
				JOIN peeps.people p ON r.person_id = p.id
				WHERE r.id = t.final_by
			) f),
		(SELECT json_agg(rp) AS replaced FROM (
			SELECT id, replaced_by, translation
			FROM words.replaced
			WHERE translation_id = $1
			ORDER BY id
		) rp),
		(SELECT json_agg(q) AS questions FROM (
			SELECT id, asked_by, created_at, question, answer
			FROM words.questions
			WHERE translation_id = $1
			ORDER BY id
		) q)
		FROM words.translations t
		JOIN words.sentences s ON t.sentence_code = s.code
		JOIN words.articles a ON s.article_id = a.id
		WHERE t.id = $1
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
	status := 200;
END;
$$ LANGUAGE plpgsql;
