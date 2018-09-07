-- PARAMS: table name, id, json, array of cols that ARE allowed to be updated
CREATE OR REPLACE FUNCTION core.jsonupdate(text, integer, json, text[]) RETURNS VOID AS $$
DECLARE
	col record;
BEGIN
	FOR col IN SELECT name FROM json_object_keys($3) AS name LOOP
		CONTINUE WHEN col.name != ALL($4);
		EXECUTE format ('UPDATE %s SET %I =
			(SELECT %I FROM json_populate_record(null::%s, $1)) WHERE id = %L',
			$1, col.name, col.name, $1, $2) USING $3;
	END LOOP;
END;
$$ LANGUAGE plpgsql;
