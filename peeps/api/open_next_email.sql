-- Opens email (updates status as opened by this emailer) then returns view
--Route{
--  api = "peeps.open_next_email",
--  args = {"emailer_id", "profile", "category"},
--  method = "POST",
--  url = "/next/([0-9]+)/([a-z@]+)/([a-zA-Z@.-]+)",
--  captures = {"emailer_id", "profile", "category"},
--}
CREATE OR REPLACE FUNCTION peeps.open_next_email(integer, text, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
	email_id integer;
BEGIN
	SELECT id INTO email_id
	FROM peeps.emails
	-- TODO: OPTIMIZE THIS: WHERE id IN (SELECT * FROM peeps.unopened_email_ids($1))
	WHERE opened_by IS NULL
	AND profile = $2
	AND category = $3
	ORDER BY id LIMIT 1;
	IF email_id IS NULL THEN status := 404;
	js := '{}'; RETURN; END IF;
	PERFORM peeps.open_email($1, email_id);
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = email_id;
	status := 200;
END;
$$ LANGUAGE plpgsql;
