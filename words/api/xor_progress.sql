-- status of all translators : from least-active to most-active
CREATE OR REPLACE FUNCTION words.xor_progress(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
	SELECT *, (t_done + r1_done + r2_done + f_done) AS finished FROM (
		SELECT r.id, r.lang, r.roll, p.name,
		(SELECT COUNT(*) FROM words.translations WHERE translated_by = r.id) AS t_claim,
		(SELECT COUNT(*) FROM words.translations WHERE translated_by = r.id AND translated_at IS NOT NULL) AS t_done,
		(SELECT COUNT(*) FROM words.translations WHERE review1_by = r.id) AS r1_claim,
		(SELECT COUNT(*) FROM words.translations WHERE review1_by = r.id AND review1_at IS NOT NULL) AS r1_done,
		(SELECT COUNT(*) FROM words.translations WHERE review2_by = r.id) AS r2_claim,
		(SELECT COUNT(*) FROM words.translations WHERE review2_by = r.id AND review2_at IS NOT NULL) AS r2_done,
		(SELECT COUNT(*) FROM words.translations WHERE final_by = r.id) AS f_claim,
		(SELECT COUNT(*) FROM words.translations WHERE final_by = r.id AND final_at IS NOT NULL) AS f_done
		FROM words.translators r
		JOIN peeps.people p ON r.person_id = p.id
		) x
	ORDER BY finished, id) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;
