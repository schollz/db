-- PARAMS: questions.id, myreply
CREATE OR REPLACE FUNCTION words.answer_question(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	ques text;
	ence text;
	tion text;
	aid integer;
	pid integer;
	eid integer;
BEGIN
	-- pid=person_id, ques=question, ence=sentence, tion=translation, aid=article_id
	SELECT r.person_id, q.question, s.sentence, t.translation, s.article_id
		INTO pid, ques, ence, tion, aid
	FROM words.questions q
	JOIN words.translations t ON q.translation_id = t.id
	JOIN words.sentences s ON t.sentence_code = s.code
	JOIN words.translators r ON q.asked_by = r.id
	WHERE q.id = $1;
	UPDATE words.questions SET answer = $2 WHERE id = $1;
	-- PARAMS: emailer_id, person_id, profile, category, subject, body, reference_id (NULL unless reply)
	SELECT * INTO eid FROM peeps.outgoing_email(1, pid, 'sivers', 'sivers',
		CONCAT('your translation question [', $1, ']'),
		CONCAT('ARTICLE: https://tr.sivers.org/article/', aid, E'\n',
			'SENTENCE: ', ence, E'\n',
			'TRANSLATION: ', tion, E'\n',
			'YOUR QUESTION: ', ques, E'\n',
			'MY REPLY: ', E'\n\n', $2),
		NULL
	);
	status := 200;
	js := json_build_object('email_id', eid);
EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);
END;
$$ LANGUAGE plpgsql;
