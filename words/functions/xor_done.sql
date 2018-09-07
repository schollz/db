-- translation.ids this translator has finished (no matter what role)
-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.xor_done(integer) RETURNS SETOF integer AS $$
	SELECT id
	FROM words.translations
	WHERE (translated_by = $1 AND translated_at IS NOT NULL)
	OR (review1_by = $1 AND review1_at IS NOT NULL)
	OR (review2_by = $1 AND review2_at IS NOT NULL)
	OR (final_by = $1 AND final_at IS NOT NULL)
	ORDER BY id;
$$ LANGUAGE SQL STABLE;
