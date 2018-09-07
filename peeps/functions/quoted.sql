-- Quote previous-email text, with a couple line breaks first. NULL if NULL
CREATE OR REPLACE FUNCTION peeps.quoted(text) RETURNS text AS $$
BEGIN
	IF $1 IS NULL THEN
		RETURN NULL;
	ELSE
		RETURN CONCAT(E'\n\n', regexp_replace($1, '^', '> ', 'ng'));
	END IF;
END;
$$ LANGUAGE plpgsql;
