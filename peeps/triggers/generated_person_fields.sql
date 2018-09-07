-- Create "address" (first word of name) and random password upon insert of new person
CREATE OR REPLACE FUNCTION peeps.generated_person_fields() RETURNS TRIGGER AS $$
BEGIN
	NEW.address = split_part(btrim(regexp_replace(NEW.name, '\s+', ' ', 'g')), ' ', 1);
	NEW.lopass = core.random_string(4);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS generate_person_fields ON peeps.people CASCADE;
CREATE TRIGGER generate_person_fields
	BEFORE INSERT ON peeps.people
	FOR EACH ROW EXECUTE PROCEDURE peeps.generated_person_fields();
