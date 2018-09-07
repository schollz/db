CREATE OR REPLACE FUNCTION words.sentences_code_gen() RETURNS TRIGGER AS $$
BEGIN
	NEW.code = core.unique_for_table_field(8, 'words.sentences', 'code');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS sentences_code_gen ON words.sentences CASCADE;
CREATE TRIGGER sentences_code_gen
	BEFORE INSERT ON words.sentences
	FOR EACH ROW WHEN (NEW.code IS NULL)
	EXECUTE PROCEDURE words.sentences_code_gen();
