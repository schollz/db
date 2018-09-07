CREATE OR REPLACE FUNCTION peeps.no2q_email(integer) RETURNS BOOLEAN as $$
DECLARE
	diff integer;
BEGIN
	diff := (LENGTH(body) - LENGTH(no2q(body))) FROM peeps.emails WHERE id = $1;
	IF (diff > 300) THEN
		UPDATE peeps.emails SET body = no2q(body) WHERE id = $1;
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$ LANGUAGE plpgsql;

