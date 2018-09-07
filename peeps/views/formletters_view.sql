DROP VIEW IF EXISTS peeps.formletters_view CASCADE;
CREATE VIEW peeps.formletters_view AS
	SELECT id,
	accesskey,
	title,
	explanation,
	created_at
	FROM peeps.formletters;
