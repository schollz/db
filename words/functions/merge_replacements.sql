-- PARAMS: $1 = "the <sentence text> like <this>", $2 = array of replacements
-- OUT: 'the <a href="/something">sentence text</a> like <strong>this</strong>'
CREATE OR REPLACE FUNCTION words.merge_replacements(text, text[], OUT merged text) AS $$
DECLARE
	split_text text[];
BEGIN
	-- make array of text bits *around* and inbetween the < and > (not including them)
	split_text := regexp_split_to_array($1, E'[<>]');
	-- take all the j, below, merged into one string
	merged := string_agg(j, '') FROM (
		-- unnest returns 2 columns, renamed to a and b, then concat that pair into j
		SELECT CONCAT(a, b) AS j
		FROM unnest(split_text, $2) x(a, b)
	) r;
END;
$$ LANGUAGE plpgsql;
