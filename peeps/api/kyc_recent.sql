CREATE OR REPLACE FUNCTION peeps.kyc_recent(
	OUT status smallint, OUT js jsonb) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id, name, email, checked_by, checked_at
		FROM peeps.people
		WHERE checked_by IN (18, 19)
		ORDER BY checked_by ASC, checked_at DESC
		LIMIT 500
	) r;
END;
$$ LANGUAGE plpgsql;

COMMIT;
