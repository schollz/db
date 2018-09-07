-- PARAMS: translators.id, articles.id
-- OUT: NULL if not-assigned in coltranes
-- 'none' = nobody claimed
-- 'gone' = someone else claimed
-- 'gogo' = claimed but not started (none done)
-- 'some' = started (some but not all done)
-- 'done' = all done
CREATE OR REPLACE FUNCTION words.xor_article_state(integer, integer) RETURNS char(4) AS $$
DECLARE
	role smallint;
	tids integer[];
BEGIN
	role := words.xor_article_role($1, $2);
	IF role IS NULL THEN RETURN NULL; END IF;
	-- save the translations.ids we're going to query repeatedly
	SELECT array_agg(e) INTO tids FROM (
		SELECT * FROM words.tids_for_article_xor($2, $1) e
	) z;
	CASE role
	WHEN 1 THEN
		-- TODO: this is ridiculously inefficient! each when-case could probably be done with one window query
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND translated_by IS NULL;
		IF FOUND THEN RETURN 'none'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND translated_by = $1;
		IF NOT FOUND THEN RETURN 'gone'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND translated_at IS NOT NULL;
		IF NOT FOUND THEN RETURN 'gogo'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND translated_at IS NULL;
		IF NOT FOUND THEN RETURN 'done'; ELSE RETURN 'some'; END IF;
	WHEN 2 THEN
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review1_by IS NULL;
		IF FOUND THEN RETURN 'none'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review1_by = $1;
		IF NOT FOUND THEN RETURN 'gone'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review1_at IS NOT NULL;
		IF NOT FOUND THEN RETURN 'gogo'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review1_at IS NULL;
		IF NOT FOUND THEN RETURN 'done'; ELSE RETURN 'some'; END IF;
	WHEN 3 THEN
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review2_by IS NULL;
		IF FOUND THEN RETURN 'none'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review2_by = $1;
		IF NOT FOUND THEN RETURN 'gone'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review2_at IS NOT NULL;
		IF NOT FOUND THEN RETURN 'gogo'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review2_at IS NULL;
		IF NOT FOUND THEN RETURN 'done'; ELSE RETURN 'some'; END IF;
	WHEN 9 THEN
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND final_by IS NULL;
		IF FOUND THEN RETURN 'none'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND final_by = $1;
		IF NOT FOUND THEN RETURN 'gone'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND final_at IS NOT NULL;
		IF NOT FOUND THEN RETURN 'gogo'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND final_at IS NULL;
		IF NOT FOUND THEN RETURN 'done'; ELSE RETURN 'some'; END IF;
	END CASE;
END;
$$ LANGUAGE plpgsql;
