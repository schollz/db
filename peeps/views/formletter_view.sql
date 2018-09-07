DROP VIEW IF EXISTS peeps.formletter_view CASCADE;
CREATE VIEW peeps.formletter_view AS
	SELECT id,
	accesskey,
	title,
	explanation,
	body,
	subject,
	created_at
	FROM peeps.formletters;
