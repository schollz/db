DROP VIEW IF EXISTS peeps.kyc_view CASCADE;
CREATE VIEW peeps.kyc_view AS
	SELECT id,
	name,
	address,
	email,
	company,
	city,
	state,
	country,
	checked_at,
	checked_by, (
		SELECT json_agg(s) AS stats
		FROM (
			SELECT statkey AS name,
			statvalue AS value
			FROM peeps.stats
			WHERE person_id = peeps.people.id
			AND statkey NOT IN ('clearbit', 'listype', 'ebook', 'musicthoughts', 'sivers.org', 'muckwork', 'songtest', 'twitter', 'download', 'ayw', 'gravatar', 'musicthought', 'forgot', 'mp3dl', 'paypal')
			ORDER BY id
		) s
	), (
		SELECT json_agg(u) AS urls
		FROM (
			SELECT id,
			url,
			main
			FROM peeps.urls
			WHERE person_id = peeps.people.id
			ORDER BY main DESC NULLS LAST, id
		) u
	), (
		SELECT json_agg(b) AS attributes
		FROM (
			SELECT atkey, plusminus
			FROM peeps.atkeys
				LEFT JOIN peeps.attributes ON (
					peeps.atkeys.atkey = peeps.attributes.attribute
					AND peeps.attributes.person_id = peeps.people.id
				)
			ORDER BY peeps.atkeys.atkey
		) b
	), (
		SELECT json_agg(c) AS interests
		FROM (
			SELECT interest, expert
			FROM peeps.interests
			WHERE person_id = peeps.people.id
			ORDER BY expert DESC, interest ASC
		) c
	), (
		SELECT json_agg(e) AS emails
		FROM (
			SELECT body,
			to_json(ARRAY(SELECT core.urls_in_text(body))) AS urls
			FROM peeps.emails
			WHERE person_id = peeps.people.id
			AND outgoing IS FALSE
			ORDER BY id DESC
		) e
	)
	FROM peeps.people;
