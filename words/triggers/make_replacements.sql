-- the extra requirement for NEW.replacements to be empty is because
-- of database dump loading: it was overwriting already-done replacements
CREATE OR REPLACE FUNCTION words.make_replacements() RETURNS TRIGGER AS $$
BEGIN
	NEW.replacements = ARRAY(SELECT unnest(regexp_matches(NEW.sentence, E'<[^>]+>', 'g')));
	NEW.sentence = replace(NEW.sentence, NEW.replacements[1], '<');
	NEW.sentence = replace(NEW.sentence, NEW.replacements[2], '>');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS make_replacements ON words.sentences CASCADE;
CREATE TRIGGER make_replacements
	BEFORE INSERT ON words.sentences
	FOR EACH ROW WHEN (
		NEW.sentence LIKE '%<%' AND (
			NEW.replacements IS NULL OR NEW.replacements = '{}'))
	EXECUTE PROCEDURE words.make_replacements();
