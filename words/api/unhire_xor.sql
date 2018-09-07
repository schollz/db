-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.unhire_xor(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	cid smallint;
BEGIN
	INSERT INTO words.candidates(person_id, lang, role, expert, yesno, has_emailed, notes)
	SELECT person_id, lang, 'zzz', 'zzz', false, true, 'removed from translators for doing nothing'
	FROM words.translators
	WHERE id = $1
	RETURNING id INTO cid;
	DELETE FROM words.coltranes WHERE translator_id = $1;
	DELETE FROM words.translators WHERE id = $1;
	status := 200;
	js := row_to_json(r) FROM (
		SELECT *
		FROM words.candidates
		WHERE id = cid) r;
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
