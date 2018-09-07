-- status only: this emailer_id has permission to update this person_id?
-- PARAMS: emailer_id, person_id
CREATE OR REPLACE FUNCTION peeps.kyc_ok_person(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := '{}';
	PERFORM 1 FROM peeps.people
		WHERE id = $2
		AND checked_by = $1
		AND checked_at IS NULL;
	IF NOT FOUND THEN status := 404;
	js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
