-- Statkey has no whitespace at all. Statvalue trimmed but keeps inner whitespace.
CREATE OR REPLACE FUNCTION peeps.clean_stats() RETURNS TRIGGER AS $$
BEGIN
	NEW.statkey = lower(regexp_replace(NEW.statkey, '[^[:alnum:]._-]', '', 'g'));
	IF NEW.statkey = '' THEN
		RAISE 'stats.key must not be empty';
	END IF;
	NEW.statvalue = btrim(NEW.statvalue, E'\r\n\t ');
	IF NEW.statvalue = '' THEN
		RAISE 'stats.value must not be empty';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_stats ON peeps.stats CASCADE;
CREATE TRIGGER clean_stats
	BEFORE INSERT OR UPDATE OF statkey, statvalue ON peeps.stats
	FOR EACH ROW EXECUTE PROCEDURE peeps.clean_stats();
