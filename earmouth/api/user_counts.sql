-- PARAMS: users.id
CREATE OR REPLACE FUNCTION earmouth.user_counts(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	connected integer;
	unconnected integer;
	request_out integer;
	request_in integer;
BEGIN
	SELECT COUNT(*) INTO connected
		FROM earmouth.connected_userids_for($1);
	SELECT COUNT(*) INTO unconnected
		FROM earmouth.unconnected_userids_for($1);
	SELECT COUNT(*) INTO request_out
		FROM earmouth.request_out_userids_for($1);
	SELECT COUNT(*) INTO request_in
		FROM earmouth.request_in_userids_for($1);
	status := 200;
	js := json_build_object(
		'connected', connected,
		'unconnected', unconnected,
		'request_out', request_out,
		'request_in', request_in
	);
END;
$$ LANGUAGE plpgsql;

