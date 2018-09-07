-- PARAMS: people.id, formletters.id
CREATE OR REPLACE FUNCTION peeps.parse_formletter_body(integer, integer,
	OUT body text) AS $$
DECLARE
	thisvar text;
	thisval text;
BEGIN
	SELECT f.body INTO body FROM peeps.formletters f WHERE id = $2;
	FOR thisvar IN SELECT regexp_matches(f.body, '{([^}]+)}', 'g')
		FROM peeps.formletters f WHERE id = $2 LOOP
		EXECUTE format ('SELECT %s::text FROM peeps.people WHERE id=%L',
			btrim(thisvar, '{}'), $1) INTO thisval;
		body := replace(body, thisvar, thisval);
	END LOOP;
END;
$$ LANGUAGE plpgsql;
