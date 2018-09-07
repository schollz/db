CREATE OR REPLACE FUNCTION earmouth.usergen() RETURNS TRIGGER AS $$
BEGIN
	NEW.apiuser = core.unique_for_table_field(8, 'earmouth.users', 'apiuser');
	NEW.apipass = core.unique_for_table_field(8, 'earmouth.users', 'apipass');
	NEW.public_id = core.unique_for_table_field(3, 'earmouth.users', 'public_id');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS usergen ON earmouth.users CASCADE;
CREATE TRIGGER usergen
	BEFORE INSERT ON earmouth.users
	FOR EACH ROW WHEN (NEW.apiuser IS NULL AND NEW.apipass IS NULL AND NEW.public_id IS NULL)
	EXECUTE PROCEDURE earmouth.usergen();

