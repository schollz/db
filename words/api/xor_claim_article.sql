-- translator wants to claim this article  (no response if success)
-- PARAMS: translators.id, articles.id
CREATE OR REPLACE FUNCTION words.xor_claim_article(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	role smallint;
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	-- refuse if they have other articles unfinished
	PERFORM 1 FROM words.articles_xor_state($1, 'do');
	IF FOUND THEN RAISE 'finish others first'; END IF;
	-- refuse unless in list of articles with 'claim' state
	PERFORM 1 FROM words.articles_xor_state($1, 'claim') x WHERE x = $2;
	IF NOT FOUND THEN RAISE 'you can not claim'; END IF;
	-- ok 
	SELECT * INTO role FROM words.xor_article_role($1, $2);
	CASE role
		WHEN 1 THEN
			UPDATE words.translations
			SET translated_by = $1
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor($2, $1));
		WHEN 2 THEN
			UPDATE words.translations
			SET review1_by = $1
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor($2, $1));
		WHEN 3 THEN
			UPDATE words.translations
			SET review2_by = $1
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor($2, $1));
		WHEN 9 THEN
			UPDATE words.translations
			SET final_by = $1
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor($2, $1));
	END CASE;
	status := 200;
	js := '{}';
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
