-- CREATE A NEW OUTGING EMAIL
-- PARAMS: emailer_id, person_id, profile, category, subject, body, reference_id (NULL unless reply)
CREATE OR REPLACE FUNCTION peeps.outgoing_email(integer, integer, text, text, text, text, integer, OUT new_id integer) AS $$
DECLARE
	p peeps.people;
	greeting text;
	new_body text;
BEGIN
	-- VERIFY INPUT:
	SELECT * INTO p FROM peeps.people WHERE id = $2;
	IF NOT FOUND THEN
		RAISE 'person_id not found';
	END IF;
	IF $4 IS NULL OR (regexp_replace($4, '\s', '', 'g') = '') THEN
		RAISE 'category must not be empty';
	END IF;
	IF $5 IS NULL OR (regexp_replace($5, '\s', '', 'g') = '') THEN
		RAISE 'subject must not be empty';
	END IF;
	IF $6 IS NULL OR (regexp_replace($6, '\s', '', 'g') = '') THEN
		RAISE 'body must not be empty';
	END IF;
	greeting := concat('Hi ', p.address);
	new_body := concat(greeting, E' -\n\n', $6, E'\n\n--\n', peeps.email_sig($3));
	INSERT INTO peeps.emails (
		person_id,
		outgoing,
		their_email, their_name,
		created_at, created_by,
		opened_at, opened_by,
		closed_at, closed_by,
		profile,
		category,
		subject,
		body,
		reference_id)
	VALUES (
		p.id,
		NULL,  --> ongoing=NULL flags for queued_emails() function to send
		p.email, p.name,
		NOW(), $1,
		NOW(), $1,
		NOW(), $1,
		$3,
		$4,
		$5,
		new_body,
		$7)
	RETURNING id INTO new_id;
END;
$$ LANGUAGE plpgsql;

