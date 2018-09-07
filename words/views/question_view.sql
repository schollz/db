DROP VIEW IF EXISTS words.question_view CASCADE;
CREATE VIEW words.question_view AS
SELECT q.id,
	s.article_id,
	a.filename,
	t.sentence_code,
	s.sentence,
	translation_id,
	t.lang,
	t.translation,
	asked_by,
	p.name,
	q.question,
	q.answer
FROM words.questions q
JOIN words.translations t ON q.translation_id = t.id
JOIN words.sentences s ON t.sentence_code = s.code
JOIN words.articles a ON s.article_id = a.id
JOIN words.translators r ON q.asked_by = r.id
JOIN peeps.people p ON r.person_id = p.id
ORDER BY q.id;

