DROP VIEW IF EXISTS peeps.email_view CASCADE;
CREATE VIEW peeps.email_view AS
	SELECT id,
	profile,
	category,
	created_at, (
		SELECT row_to_json(p1) AS creator
		FROM (
			SELECT emailers.id, people.name
			FROM peeps.emailers
				JOIN peeps.people
				ON emailers.person_id = people.id
			WHERE peeps.emailers.id = created_by
		) p1
	),
	opened_at, (
		SELECT row_to_json(p2) AS openor
		FROM (
			SELECT emailers.id, people.name
			FROM peeps.emailers
				JOIN peeps.people
				ON emailers.person_id = people.id
			WHERE peeps.emailers.id = opened_by
		) p2
	),
	closed_at, (
		SELECT row_to_json(p3) AS closor
		FROM (
			SELECT emailers.id, people.name
			FROM peeps.emailers
				JOIN peeps.people
				ON emailers.person_id = people.id
			WHERE peeps.emailers.id = closed_by
		) p3
	),
	message_id,
	outgoing,
	reference_id,
	answer_id,
	their_email,
	their_name,
	headers,
	subject,
	body,
	to_json(ARRAY(SELECT core.urls_in_text(body))) AS urls, (
		SELECT json_agg(a) AS attachments
		FROM (
			SELECT id, filename
			FROM peeps.email_attachments
			WHERE email_id = peeps.emails.id
		) a
	), (
		SELECT row_to_json(p) AS person
		FROM (
			SELECT *
			FROM peeps.person_view
			WHERE id = person_id
		) p
	)
	FROM peeps.emails;
