-- returns smallint (1/2/3) : their role in this collection (NULL = not assigned)
-- PARAMS: translators.id, collections.id
CREATE OR REPLACE FUNCTION words.xor_collection_role(integer, integer) RETURNS smallint AS $$
	SELECT r.roll
	FROM words.coltranes c
	LEFT JOIN words.translators r ON c.translator_id = r.id
	WHERE c.translator_id = $1
	AND c.collection_id = $2;
$$ LANGUAGE SQL STABLE;
