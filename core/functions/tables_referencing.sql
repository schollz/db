-- For updating foreign keys, tables referencing this column
-- tablename in schema.table format like 'woodegg.researchers' colname: 'person_id'
-- PARAMS: schema, table, column
CREATE OR REPLACE FUNCTION core.tables_referencing(text, text, text)
	RETURNS TABLE(tablename text, colname name) AS $$
BEGIN
	RETURN QUERY SELECT CONCAT(n.nspname, '.', k.relname), a.attname
		FROM pg_constraint c
		INNER JOIN pg_class k ON c.conrelid = k.oid
		INNER JOIN pg_attribute a ON c.conrelid = a.attrelid
		INNER JOIN pg_namespace n ON k.relnamespace = n.oid
		WHERE c.confrelid = (SELECT oid FROM pg_class WHERE relname = $2 
			AND relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = $1))
		AND ARRAY[a.attnum] <@ c.conkey
		AND c.confkey @> (SELECT array_agg(attnum) FROM pg_attribute
			WHERE attname = $3 AND attrelid = c.confrelid);
END;
$$ LANGUAGE plpgsql;
