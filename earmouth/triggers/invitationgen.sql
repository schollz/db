CREATE OR REPLACE FUNCTION earmouth.invitationgen() RETURNS TRIGGER AS $$
BEGIN
	NEW.code = core.unique_for_table_field(6, 'earmouth.invitations', 'code');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS invitationgen ON earmouth.invitations CASCADE;
CREATE TRIGGER invitationgen
	BEFORE INSERT ON earmouth.invitations
	FOR EACH ROW WHEN (NEW.code IS NULL)
	EXECUTE PROCEDURE earmouth.invitationgen();

