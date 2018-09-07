-- Takes the articles.raw and turns it into individual sentences,
-- then creates and saves articles.template using the newly generated codes.
-- PARAMS: articles.id
CREATE OR REPLACE FUNCTION words.parse_article(integer) RETURNS text AS $$
DECLARE
	lines text[];
	line text;
	templine text;
	new_template text := '';
	sortnum integer := 0;
	one_code char(8);
BEGIN
	-- go through every line of words.articles.raw
	SELECT regexp_split_to_array(raw, E'\n') INTO lines
	FROM words.articles
	WHERE id = $1;
	FOREACH line IN ARRAY lines LOOP
		-- if it's indented with a tab, insert it into words.sentences
		IF E'\t' = substring(line from 1 for 1) THEN
			sortnum := sortnum + 1;
			INSERT INTO words.sentences(article_id, sortid, sentence)
				VALUES ($1, sortnum, btrim(line, E'\t'))
				RETURNING code INTO one_code;
			-- use the put the generated code into the template
			new_template := new_template || '{' || one_code || '}' || E'\n';
		-- HTML comments should also be translated
		ELSIF line ~ '<!-- (.*) -->' THEN
			sortnum := sortnum + 1;
			SELECT unnest(regexp_matches) INTO templine
				FROM regexp_matches(line, '<!-- (.*) -->');
			INSERT INTO words.sentences(article_id, sortid, sentence)
				VALUES ($1, sortnum, btrim(templine))
				RETURNING code INTO one_code;
			new_template := new_template || '<!-- {' || one_code || '} -->' || E'\n';
		ELSE
			-- non-translated line (usually HTML markup), just add to template
			new_template := new_template || line || E'\n';
		END IF;
	END LOOP;
	-- and update articles with the new template
	UPDATE words.articles SET template = rtrim(new_template, E'\n') WHERE id = $1;
	RETURN rtrim(new_template, E'\n');
END;
$$ LANGUAGE plpgsql;
