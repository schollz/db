-- translation.ids this translator is waiting for (no matter what role)
-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.xor_wait(integer) RETURNS SETOF integer AS $$
	SELECT translation_id
	FROM words.questions
	WHERE asked_by = $1
	AND answer IS NULL
	ORDER BY translation_id;
$$ LANGUAGE SQL STABLE;
