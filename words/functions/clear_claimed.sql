-- un-claim articles that were claimed but not started
CREATE OR REPLACE FUNCTION words.clear_claimed() RETURNS boolean AS $$
DECLARE
	aid smallint;
	tid smallint;
	anyfound boolean;
BEGIN
	anyfound := false;
	-- do exact same loop four times. this time = translated_
	FOR aid, tid IN
	SELECT DISTINCT words.article_for_xion(id), translated_by
	FROM words.translations
	WHERE (translated_by IS NOT NULL AND translated_at IS NULL)
	LOOP
		PERFORM 1 FROM words.translations WHERE id IN (
			SELECT * FROM words.tids_for_article_xor(aid, tid))
		AND translated_at IS NOT NULL;
		IF NOT FOUND THEN
			UPDATE words.translations
			SET translated_by = NULL
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor(aid, tid)
			);
			anyfound := true;
		END IF;
	END LOOP;
	-- do exact same loop four times. this time = review1_
	FOR aid, tid IN
	SELECT DISTINCT words.article_for_xion(id), review1_by
	FROM words.translations
	WHERE (review1_by IS NOT NULL AND review1_at IS NULL)
	LOOP
		PERFORM 1 FROM words.translations WHERE id IN (
			SELECT * FROM words.tids_for_article_xor(aid, tid))
		AND review1_at IS NOT NULL;
		IF NOT FOUND THEN
			UPDATE words.translations
			SET review1_by = NULL
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor(aid, tid)
			);
			anyfound := true;
		END IF;
	END LOOP;
	-- do exact same loop four times. this time = review2_
	FOR aid, tid IN
	SELECT DISTINCT words.article_for_xion(id), review2_by
	FROM words.translations
	WHERE (review2_by IS NOT NULL AND review2_at IS NULL)
	LOOP
		PERFORM 1 FROM words.translations WHERE id IN (
			SELECT * FROM words.tids_for_article_xor(aid, tid))
		AND review2_at IS NOT NULL;
		IF NOT FOUND THEN
			UPDATE words.translations
			SET review2_by = NULL
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor(aid, tid)
			);
			anyfound := true;
		END IF;
	END LOOP;
	-- do exact same loop four times. this time = final_
	FOR aid, tid IN
	SELECT DISTINCT words.article_for_xion(id), final_by
	FROM words.translations
	WHERE (final_by IS NOT NULL AND final_at IS NULL)
	LOOP
		PERFORM 1 FROM words.translations WHERE id IN (
			SELECT * FROM words.tids_for_article_xor(aid, tid))
		AND final_at IS NOT NULL;
		IF NOT FOUND THEN
			UPDATE words.translations
			SET final_by = NULL
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor(aid, tid)
			);
			anyfound := true;
		END IF;
	END LOOP;
	-- any found in any of the four loops?
	RETURN anyfound;
END;
$$ LANGUAGE plpgsql;
