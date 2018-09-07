-- RETURNS: array of column names that ARE allowed to be updated
-- PARAMS: schema name, table name, array of col names NOT allowed to be updated
CREATE OR REPLACE FUNCTION core.cols2update(text, text, text[]) RETURNS text[] AS $$
BEGIN
	RETURN array(SELECT column_name::text FROM information_schema.columns
		WHERE table_schema=$1 AND table_name=$2 AND column_name != ALL($3));
END;
$$ LANGUAGE plpgsql;
