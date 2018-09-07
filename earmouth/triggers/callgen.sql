CREATE OR REPLACE FUNCTION earmouth.callgen() RETURNS TRIGGER AS $$
BEGIN
	NEW.public_id = core.unique_for_table_field(4, 'earmouth.calls', 'public_id');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS callgen ON earmouth.calls CASCADE;
CREATE TRIGGER callgen
	BEFORE INSERT ON earmouth.calls
	FOR EACH ROW WHEN (NEW.public_id IS NULL)
	EXECUTE PROCEDURE earmouth.callgen();

