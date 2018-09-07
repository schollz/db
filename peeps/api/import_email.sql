--JSON keys: profile category message_id their_email their_name subject headers body
--Route{
--  api = "peeps.import_email",
--  args = {"json"},
--  method = "POST",
--  url = "/email/import",
--  params = {"json"},
--}
CREATE OR REPLACE FUNCTION peeps.import_email(json,
	OUT status smallint, OUT js json) AS $$
DECLARE
	eid integer;
	pid integer;
	rid integer;
	err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	-- insert as-is (easier to update once in database)
	-- created_by = 2  TODO: created_by=NULL for imports?
	INSERT INTO peeps.emails (
		created_by,
		profile,
		category,
		message_id,
		their_email,
		their_name,
		subject,
		headers,
		body
	) SELECT
		2 AS created_by,
		profile,
		category,
		message_id,
		their_email,
		their_name,
		subject,
		headers,
		body
	FROM json_populate_record(null::peeps.emails, $1)
	RETURNING id INTO eid;
	-- if references.message_id found, update person_id, reference_id, category
	IF json_array_length($1 -> 'references') > 0 THEN
		UPDATE peeps.emails
		SET person_id = ref.person_id,
		reference_id = ref.id,
		category = COALESCE(peeps.people.categorize_as, peeps.emails.profile)
		FROM peeps.emails ref, peeps.people
		WHERE peeps.emails.id = eid
		AND ref.person_id = peeps.people.id
		AND ref.message_id IN (
			SELECT * FROM json_array_elements_text($1 -> 'references')
		)
		RETURNING emails.person_id, ref.id INTO pid, rid;
		IF rid IS NOT NULL THEN
			UPDATE peeps.emails SET answer_id = eid WHERE id = rid;
		END IF;
	END IF;
	-- if their_email is found, update person_id, category
	IF pid IS NULL THEN
		UPDATE peeps.emails e
		SET person_id = p.id,
			category = COALESCE(p.categorize_as, e.profile)
		FROM peeps.people p
		WHERE e.id = eid
		AND (p.email = e.their_email OR p.company = e.their_email)
		RETURNING e.person_id INTO pid;
	END IF;
	-- if still not found, set category to fix-client (TODO: make this unnecessary)
	IF pid IS NULL THEN
		UPDATE peeps.emails
		SET category = 'fix-client'
		WHERE id = eid
		RETURNING person_id INTO pid;
	END IF;
	-- insert attachments
	IF json_array_length($1 -> 'attachments') > 0 THEN
		INSERT INTO peeps.email_attachments(email_id, mime_type, filename, bytes)
		SELECT eid AS email_id, mime_type, filename, bytes
		FROM json_populate_recordset(null::peeps.email_attachments, $1 -> 'attachments');
	END IF;
	js := row_to_json(r.*) FROM peeps.email_view r WHERE id = eid;
	status := 200;

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
