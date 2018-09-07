-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.get_xor(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT t.*,
			p.name,
			p.email,
			p.public_id,
		(SELECT json_agg(cl) AS collections FROM (
				SELECT c.id, c.name
				FROM words.coltranes t
				JOIN words.collections c ON t.collection_id = c.id
				WHERE translator_id = $1
		) cl),
		(SELECT json_agg(t1) AS translations FROM (
				SELECT t.id,
					t.translated_at AS finished,
					t.sentence_code,
					s.sentence,
					t.translation
				FROM words.translations t
				JOIN words.sentences s ON t.sentence_code = s.code
				WHERE t.translated_by = $1
				ORDER BY t.translated_at, t.id
		) t1),
		(SELECT json_agg(t2) AS review1s FROM (
				SELECT t.id,
				t.review1_at AS finished,
				t.sentence_code,
				s.sentence,
				t.translation
				FROM words.translations t
				JOIN words.sentences s ON t.sentence_code = s.code
				WHERE t.review1_by = $1
				ORDER BY t.review1_at, t.id
		) t2),
		(SELECT json_agg(t3) AS review2s FROM (
				SELECT t.id,
				t.review2_at AS finished,
				t.sentence_code,
				s.sentence,
				t.translation
				FROM words.translations t
				JOIN words.sentences s ON t.sentence_code = s.code
				WHERE t.review2_by = $1
				ORDER BY t.review2_at, t.id
		) t3),
		(SELECT json_agg(f) AS finals FROM (
				SELECT t.id,
				t.final_at AS finished,
				t.sentence_code,
				s.sentence,
				t.translation
				FROM words.translations t
				JOIN words.sentences s ON t.sentence_code = s.code
				WHERE t.final_by = $1
				ORDER BY t.final_at, t.id
		) f),
		(SELECT json_agg(qq) AS questions FROM (
				SELECT id, article_id, filename, sentence_code, sentence,
					translation_id, lang, translation, question, answer
				FROM words.question_view
				WHERE asked_by = $1
				ORDER BY id
		) qq),
		(SELECT json_agg(rr) AS replaced FROM (
				SELECT r.id, r.translation_id,
					r.translation AS old, t.translation AS new
				FROM words.replaced r
				JOIN words.translations t ON r.translation_id = t.id
				JOIN words.sentences s ON t.sentence_code = s.code
				WHERE r.replaced_by = $1
				ORDER BY r.id
		) rr)
		FROM words.translators t
		LEFT JOIN peeps.people p ON t.person_id = p.id
		WHERE t.id = $1
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;
