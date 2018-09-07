-- ensure unique unused value for any table.field.
CREATE OR REPLACE FUNCTION core.unique_for_table_field(str_len integer, table_name text, field_name text) RETURNS text AS $$
DECLARE
	nu text;
BEGIN
	nu := core.random_string(str_len);
	LOOP
		EXECUTE 'SELECT 1 FROM ' || table_name || ' WHERE ' || field_name || ' = ' || quote_literal(nu);
		IF NOT FOUND THEN
			RETURN nu; 
		END IF;
		nu := core.random_string(str_len);
	END LOOP;
END;
$$ LANGUAGE plpgsql;
