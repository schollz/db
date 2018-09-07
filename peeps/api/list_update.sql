-- Update mailing list settings for this person (whether new or existing)
-- listype should be: all, some, none, or dead
--Route{
--  api = "peeps.list_update",
--  args = {"name", "email", "listype"},
--  method = "POST",
--  url = "/list",
--  params = {"name", " email", " listype"},
--}
CREATE OR REPLACE FUNCTION peeps.list_update(text, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
	clean3 text;
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	clean3 := regexp_replace($3, '[^a-z]', '', 'g');
	SELECT id INTO pid
	FROM peeps.person_create($1, $2);
	INSERT INTO peeps.stats(person_id, statkey, statvalue)
	VALUES (pid, 'listype', clean3);
	UPDATE peeps.people
	SET listype = clean3
	WHERE id = pid;
	status := 200;
	js := json_build_object('list', clean3);

EXCEPTION
	WHEN OTHERS THEN GET STACKED DIAGNOSTICS
		err_code = RETURNED_SQLSTATE,
		err_msg = MESSAGE_TEXT,
		err_detail = PG_EXCEPTION_DETAIL,
		err_context = PG_EXCEPTION_CONTEXT;
	status := 500;
	js := json_build_object(
		'code', err_code,
		'message', err_msg,
		'detail', err_detail,
		'context', err_context);
END;
$$ LANGUAGE plpgsql;
