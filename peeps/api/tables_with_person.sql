-- ARRAY of schema.tablenames where with this person_id
--Route{
--  api = "peeps.tables_with_person",
--  args = {"id"},
--  method = "GET",
--  url = "/person/([0-9]+)/tables",
--  captures = {"id"},
--}
CREATE OR REPLACE FUNCTION peeps.tables_with_person(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	res RECORD;
	tablez text[] := ARRAY[]::text[];
	rowcount integer;
BEGIN
	FOR res IN
		SELECT *
		FROM core.tables_referencing('peeps', 'people', 'id')
	LOOP
		EXECUTE format ('SELECT 1 FROM %s WHERE %I = %s',
			res.tablename, res.colname, $1);
		GET DIAGNOSTICS rowcount = ROW_COUNT;
		IF rowcount > 0 THEN
			tablez := tablez || res.tablename;
		END IF;
	END LOOP;
	status := 200;
	js := array_to_json(tablez);
END;
$$ LANGUAGE plpgsql;
