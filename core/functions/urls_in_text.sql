-- PARAMS: any text that might have URLs
-- returns all words with dot between not-whitespace chars (very liberal)
-- normalized without https?://, trailing dot, any <>
CREATE OR REPLACE FUNCTION core.urls_in_text(text) RETURNS SETOF text AS $$
BEGIN
	RETURN QUERY SELECT regexp_replace(
		(regexp_matches($1, '\S+\.\S+', 'g'))[1],
		'<|>|https?://|\.$', '', 'g');  
END;
$$ LANGUAGE plpgsql;
