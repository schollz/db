-- PARAMS: $1 = "the <sentence text> like <this>", $2 = array of replacements
-- BOOLEAN : does the number of <> match the number of replacements in array?
-- NOTE: This query will show translations that don't match replacements:
-- SELECT translations.id, replacements, translation FROM words.translations
-- JOIN words.sentences ON translations.sentence_code=sentences.code
-- WHERE words.tags_match_replacements(translation, replacements) IS FALSE;
-- NOTE: If that ends up being my main usage for it, then this isn't needed as
-- a separate function, could just use the brackets-to-cardinality comparison
-- in the query itself.
-- NOTE: Though it might be a UI thing for translators: let them know it's ok or not
CREATE OR REPLACE FUNCTION words.tags_match_replacements(text, text[], OUT ok boolean) AS $$
DECLARE
	howmany_brackets integer;
BEGIN
	SELECT COUNT(*) INTO howmany_brackets FROM regexp_matches($1, E'[<>]', 'g');
	IF (howmany_brackets = cardinality($2)) THEN
		ok := true;
	ELSE
		ok := false;
	END IF;
END;
$$ LANGUAGE plpgsql;
