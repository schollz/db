-- PARAMS: emailer_id, person_id
CREATE OR REPLACE FUNCTION peeps.kyc_get_person(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r.*) FROM peeps.kyc_view r
		WHERE id = $2
		AND checked_by = $1
		AND checked_at IS NULL;
	status := 200;
	IF js IS NULL THEN status := 404;
	js := '{}'; END IF;
END;
$$ LANGUAGE plpgsql;
