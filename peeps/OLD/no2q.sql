-- given the body of an email, removes lines that start with ">>"
-- (strips spaces so " > > blah" lines would get removed too)
CREATE OR REPLACE FUNCTION peeps.no2q(text) RETURNS text AS $$
DECLARE
	aline text;
	newbody text := '';
BEGIN
	IF $1 IS NULL THEN
		RETURN newbody;
	ELSE
		FOREACH aline IN ARRAY regexp_split_to_array($1, E'\n') LOOP
			IF substring(replace(aline, ' ', ''), 1, 2) != '>>' THEN
				newbody := concat(newbody, aline, E'\n');
			END IF;
		END LOOP;
		RETURN newbody;
	END IF;
END;
$$ LANGUAGE plpgsql;
