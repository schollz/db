BEGIN;
SET client_min_messages TO ERROR;
SET client_encoding = 'UTF8';
DROP SCHEMA IF EXISTS words CASCADE;
CREATE SCHEMA words;
SET search_path = words;

CREATE TABLE words.candidates (
	id smallserial primary key,
	person_id integer not null UNIQUE REFERENCES peeps.people(id),
	created_at date not null default CURRENT_DATE,
	lang char(2) not null,
	role char(3) not null, -- '1st' '2nd'
	expert char(3) not null, -- 'pro' 'hob'
	yesno boolean,
	has_emailed boolean,
	notes text
);
CREATE INDEX candpi ON words.candidates(person_id);

CREATE TABLE words.translators (
	id smallserial primary key,
	person_id integer not null UNIQUE REFERENCES peeps.people(id),
	lang char(2) not null,
	roll smallint, -- 1=translation, 2=review1, 3=review2
	notes text
);

-- "collection" website/book : a project to get translated
CREATE TABLE words.collections (
	id smallserial primary key,
	name text not null unique
);

CREATE TABLE words.coltranes (
	collection_id smallint REFERENCES words.collections(id),
	translator_id smallint REFERENCES words.translators(id),
	role smallint, -- 1=translation, 2=review1, 3=review2
	primary key (collection_id, translator_id)
);

-- "article" meaning ordered collection of sentences, with HTML markup
CREATE TABLE words.articles (
	id smallserial primary key,
	collection_id smallint REFERENCES words.collections(id),
	filename varchar(64) not null unique,
	raw text,  -- insert here
	template text  -- this is generated
);

CREATE TABLE words.sentences (
	code char(8) primary key,
	article_id smallint REFERENCES words.articles(id),
	sortid smallint,
	sentence text,
	replacements text[] DEFAULT '{}',
	comment text  -- my comment to translators
);

CREATE TABLE words.translations (
	id serial primary key,
	sentence_code char(8) not null REFERENCES words.sentences(code),
	lang char(2) not null,
	translated_by smallint REFERENCES words.translators(id), -- claimed by
	translated_at timestamp(0) with time zone, -- finished
	review1_by smallint REFERENCES words.translators(id),
	review1_at timestamp(0) with time zone, --finished
	review2_by smallint REFERENCES words.translators(id),
	review2_at timestamp(0) with time zone, --finished
	final_by smallint REFERENCES words.translators(id),
	final_at timestamp(0) with time zone, --finished
	translation text,
	UNIQUE (sentence_code, lang)
);
CREATE INDEX trl ON words.translations(lang);
CREATE INDEX trs ON words.translations(sentence_code);
CREATE INDEX trtb ON words.translations(translated_by);
CREATE INDEX trta ON words.translations(translated_at);
CREATE INDEX trr1b ON words.translations(review1_by);
CREATE INDEX trr1a ON words.translations(review1_at);
CREATE INDEX trr2b ON words.translations(review2_by);
CREATE INDEX trr2a ON words.translations(review2_at);
CREATE INDEX trfb ON words.translations(final_by);
CREATE INDEX trfa ON words.translations(final_at);

CREATE TABLE words.replaced (
	id serial primary key,
	translation_id integer not null REFERENCES words.translations(id),
	replaced_by smallint not null REFERENCES words.translators(id),
	translation text
);

CREATE TABLE words.questions (
	id serial primary key,
	translation_id integer not null REFERENCES words.translations(id),
	asked_by smallint not null REFERENCES words.translators(id),
	created_at date not null default CURRENT_DATE,
	question text not null,
	answer text
);
CREATE INDEX qaba ON words.questions(asked_by, answer);

-- "Your Music and People"
CREATE TABLE words.metabooks (
	id smallserial primary key,
	title varchar(64) unique,
	title_code char(8) REFERENCES words.sentences(code),
	subtitle varchar(64),
	subtitle_code char(8) REFERENCES words.sentences(code)
);

CREATE TABLE words.chapters (
	metabook_id smallint not null REFERENCES words.metabooks(id),
	article_id smallint not null REFERENCES words.articles(id),
	sortid smallint,
	title char(8) REFERENCES words.sentences(code),
	primary key (metabook_id, article_id)
);

-- pt:"Sua Música e Pessoas"
CREATE TABLE words.books (
	id smallserial primary key,
	metabook_id smallint not null REFERENCES words.metabooks(id),
	lang char(2),
	title varchar(64),
	title_translation integer REFERENCES words.translations(id),
	subtitle varchar(64),
	subtitle_translation integer REFERENCES words.translations(id)
);

-- format:epub|mobi|audio|pdf|paper + isbn
CREATE TABLE words.book_formats (
	id smallserial primary key,
	book_id smallint not null REFERENCES words.books(id),
	format varchar(5) not null,
	isbn varchar(13) unique
);



DROP VIEW IF EXISTS words.question_view CASCADE;
CREATE VIEW words.question_view AS
SELECT q.id,
	s.article_id,
	a.filename,
	t.sentence_code,
	s.sentence,
	translation_id,
	t.lang,
	t.translation,
	asked_by,
	p.name,
	q.question,
	q.answer
FROM words.questions q
JOIN words.translations t ON q.translation_id = t.id
JOIN words.sentences s ON t.sentence_code = s.code
JOIN words.articles a ON s.article_id = a.id
JOIN words.translators r ON q.asked_by = r.id
JOIN peeps.people p ON r.person_id = p.id
ORDER BY q.id;



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


-- PARAMS: $1 = "the <sentence text> like <this>", $2 = array of replacements
-- BOOLEAN : does the number of <> match the number of replacements in array?
-- NOTE: This query will show translations that don't match replacements:
-- SELECT translations.id, replacements, translation FROM words.translations
-- JOIN words.sentences ON translations.sentence_code=sentences.code
-- WHERE words.tags_match_replacements(translation, replacements) IS FALSE;
-- NOTE: If that ends up being my main usage for it, then this isn't needed as
-- a separate function, could just use the brackets-to-cardinality comparison
-- in the query itself.
-- NOTE: Though it might be a UI thing for translators: let them know it's ok or not
CREATE OR REPLACE FUNCTION words.tags_match_replacements(text, text[], OUT ok boolean) AS $$
DECLARE
	howmany_brackets integer;
BEGIN
	SELECT COUNT(*) INTO howmany_brackets FROM regexp_matches($1, E'[<>]', 'g');
	IF (howmany_brackets = cardinality($2)) THEN
		ok := true;
	ELSE
		ok := false;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: $1 = "the <sentence text> like <this>", $2 = array of replacements
-- OUT: 'the <a href="/something">sentence text</a> like <strong>this</strong>'
CREATE OR REPLACE FUNCTION words.merge_replacements(text, text[], OUT merged text) AS $$
DECLARE
	split_text text[];
BEGIN
	-- make array of text bits *around* and inbetween the < and > (not including them)
	split_text := regexp_split_to_array($1, E'[<>]');
	-- take all the j, below, merged into one string
	merged := string_agg(j, '') FROM (
		-- unnest returns 2 columns, renamed to a and b, then concat that pair into j
		SELECT CONCAT(a, b) AS j
		FROM unnest(split_text, $2) x(a, b)
	) r;
END;
$$ LANGUAGE plpgsql;


-- Get the entire translated text for this article, merged into template
-- PARAMS: articles.id, 2-char lang code
CREATE OR REPLACE FUNCTION words.merge_article(integer, char(2), OUT merged text) AS $$
DECLARE
	a RECORD;
BEGIN
	SELECT template INTO merged
	FROM words.articles
	WHERE id = $1;
	-- if English, get from sentences.sentence, not translations.translation
	IF $2 = 'en' THEN
		FOR a IN
			SELECT code,
				words.merge_replacements(sentence, replacements) AS txn
			FROM words.sentences
			WHERE article_id = $1
			ORDER BY sortid
			LOOP
				merged := replace(merged, '{' || a.code || '}', COALESCE(a.txn, ''));
			END LOOP;
	ELSE
		FOR a IN
			SELECT code,
				words.merge_replacements(translation, replacements) AS txn
			FROM words.sentences s
			JOIN words.translations t ON s.code = t.sentence_code
			WHERE article_id = $1
			AND lang = $2
			ORDER BY s.sortid
			LOOP
				merged := replace(merged, '{' || a.code || '}', COALESCE(a.txn, ''));
			END LOOP;
	END IF;
END;
$$ LANGUAGE plpgsql;


-- creates empty translations if none exist for all the sentences in this collection
-- returns list of translation.ids 
-- PARAMS: collections.id, lang
CREATE OR REPLACE FUNCTION words.init_collection_lang(integer, char(2)) RETURNS SETOF integer AS $$
BEGIN
	-- do query first just to see if exists
	PERFORM t.id
	FROM words.translations t
	JOIN words.sentences s ON t.sentence_code = s.code
	JOIN words.articles a ON s.article_id = a.id
	WHERE a.collection_id = $1
	AND t.lang = $2 LIMIT 1;
	IF NOT FOUND THEN
		-- insert if none
		INSERT INTO words.translations(sentence_code, lang)
			SELECT code, $2 AS lang
			FROM words.sentences s
			JOIN words.articles a ON s.article_id = a.id
			WHERE a.collection_id = $1
			ORDER BY a.id, s.sortid;
	END IF;
	-- now return translation.ids
	RETURN QUERY SELECT t.id
	FROM words.translations t
	JOIN words.sentences s ON t.sentence_code = s.code
	JOIN words.articles a ON s.article_id = a.id
	WHERE a.collection_id = $1
	AND t.lang = $2
	ORDER BY t.id;
END;
$$ LANGUAGE plpgsql;


-- returns smallint (1/2/3) : their role in this collection (NULL = not assigned)
-- PARAMS: translators.id, collections.id
CREATE OR REPLACE FUNCTION words.xor_collection_role(integer, integer) RETURNS smallint AS $$
	SELECT r.roll
	FROM words.coltranes c
	LEFT JOIN words.translators r ON c.translator_id = r.id
	WHERE c.translator_id = $1
	AND c.collection_id = $2;
$$ LANGUAGE SQL STABLE;


-- returns smallint (1/2/3) : their role in this article (NULL = not assigned)
-- PARAMS: translators.id, articles.id
CREATE OR REPLACE FUNCTION words.xor_article_role(integer, integer) RETURNS smallint AS $$
	SELECT r.roll
	FROM words.coltranes c
	JOIN words.articles a ON a.collection_id = c.collection_id
	LEFT JOIN words.translators r ON c.translator_id = r.id
	WHERE c.translator_id = $1
	AND a.id = $2;
$$ LANGUAGE SQL STABLE;


-- returns smallint (1/2/3) : their role in this translation (NULL = not assigned)
-- PARAMS: translators.id, translations.id
CREATE OR REPLACE FUNCTION words.xor_xion_role(integer, integer) RETURNS smallint AS $$
	SELECT r.roll
	FROM words.coltranes c
	LEFT JOIN words.translators r ON c.translator_id = r.id
	JOIN words.articles a ON a.collection_id = c.collection_id
	JOIN words.sentences s ON s.article_id = a.id
	JOIN words.translations t
		ON (t.sentence_code = s.code AND t.lang = r.lang)
	WHERE c.translator_id = $1
	AND t.id = $2;
$$ LANGUAGE SQL STABLE;


-- translation.ids this translator has started but not finished (no matter what role)
-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.xor_do(integer) RETURNS SETOF integer AS $$
	SELECT id
	FROM words.translations
	WHERE (translated_by = $1 AND translated_at IS NULL)
	OR (review1_by = $1 AND review1_at IS NULL)
	OR (review2_by = $1 AND review2_at IS NULL)
	OR (final_by = $1 AND final_at IS NULL)
	ORDER BY id;
$$ LANGUAGE SQL STABLE;


-- translation.ids this translator can claim
-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.xor_claim(integer) RETURNS SETOF integer AS $$
	SELECT t.id
	FROM words.translators r
	JOIN words.coltranes c ON c.translator_id = r.id
	JOIN words.articles a ON a.collection_id = c.collection_id
	JOIN words.sentences s ON s.article_id = a.id
	JOIN words.translations t ON (t.sentence_code = s.code AND t.lang = r.lang)
	WHERE r.id = $1
	AND ((r.roll = 1 AND t.translated_by IS NULL)
		OR (r.roll = 2 AND t.translated_at IS NOT NULL AND t.review1_by IS NULL)
		OR (r.roll = 3 AND t.review1_at IS NOT NULL AND t.review2_by IS NULL)
		OR (r.roll = 9 AND t.final_by IS NULL))
	ORDER BY t.id;
$$ LANGUAGE SQL STABLE;


-- translation.ids this translator is waiting for (no matter what role)
-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.xor_wait(integer) RETURNS SETOF integer AS $$
	SELECT translation_id
	FROM words.questions
	WHERE asked_by = $1
	AND answer IS NULL
	ORDER BY translation_id;
$$ LANGUAGE SQL STABLE;


-- translation.ids this translator has finished (no matter what role)
-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.xor_done(integer) RETURNS SETOF integer AS $$
	SELECT id
	FROM words.translations
	WHERE (translated_by = $1 AND translated_at IS NOT NULL)
	OR (review1_by = $1 AND review1_at IS NOT NULL)
	OR (review2_by = $1 AND review2_at IS NOT NULL)
	OR (final_by = $1 AND final_at IS NOT NULL)
	ORDER BY id;
$$ LANGUAGE SQL STABLE;


-- articles.ids with state: 'do', 'claim', 'wait', 'done'
-- PARAMS: translators.id, 'do|claim|done'
CREATE OR REPLACE FUNCTION words.articles_xor_state(integer, text) RETURNS SETOF smallint AS $$
BEGIN
	CASE $2
		WHEN 'claim' THEN -- if any translations can be "claim"ed then article can
			RETURN QUERY SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_claim($1));
		WHEN 'do' THEN -- if any translations are "do" then article is "do", unless "wait"
			RETURN QUERY SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_do($1))
			EXCEPT
			SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_wait($1));
		WHEN 'wait' THEN -- if any translations are "wait" then article is "wait"
			RETURN QUERY SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_wait($1));
		WHEN 'done' THEN -- done minus do = completely done
			RETURN QUERY SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_done($1))
			EXCEPT
			SELECT DISTINCT(a.id)
			FROM words.articles a
			JOIN words.sentences s ON s.article_id = a.id
			JOIN words.translations t ON t.sentence_code = s.code
			WHERE t.id IN (SELECT * FROM words.xor_do($1));
	END CASE;
END;
$$ LANGUAGE plpgsql;


-- get translation.ids for this article for this translator's language
-- PARAMS: articles.id, translators.id
CREATE OR REPLACE FUNCTION words.tids_for_article_xor(integer, integer) RETURNS SETOF integer AS $$
	SELECT t.id
	FROM words.translations t
	JOIN words.sentences s ON t.sentence_code = s.code
	JOIN words.translators r ON r.id = $2 
	WHERE s.article_id = $1
	AND t.lang = r.lang
	ORDER BY t.id;
$$ LANGUAGE SQL STABLE;


-- PARAMS: translations.id
-- RETURNS: article_id
CREATE OR REPLACE FUNCTION words.article_for_xion(integer) RETURNS smallint AS $$
	SELECT s.article_id
	FROM words.translations t
	JOIN words.sentences s ON t.sentence_code = s.code
	WHERE t.id = $1;
$$ LANGUAGE SQL STABLE;


-- PARAMS: translators.id, articles.id
-- OUT: NULL if not-assigned in coltranes
-- 'none' = nobody claimed
-- 'gone' = someone else claimed
-- 'gogo' = claimed but not started (none done)
-- 'some' = started (some but not all done)
-- 'done' = all done
CREATE OR REPLACE FUNCTION words.xor_article_state(integer, integer) RETURNS char(4) AS $$
DECLARE
	role smallint;
	tids integer[];
BEGIN
	role := words.xor_article_role($1, $2);
	IF role IS NULL THEN RETURN NULL; END IF;
	-- save the translations.ids we're going to query repeatedly
	SELECT array_agg(e) INTO tids FROM (
		SELECT * FROM words.tids_for_article_xor($2, $1) e
	) z;
	CASE role
	WHEN 1 THEN
		-- TODO: this is ridiculously inefficient! each when-case could probably be done with one window query
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND translated_by IS NULL;
		IF FOUND THEN RETURN 'none'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND translated_by = $1;
		IF NOT FOUND THEN RETURN 'gone'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND translated_at IS NOT NULL;
		IF NOT FOUND THEN RETURN 'gogo'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND translated_at IS NULL;
		IF NOT FOUND THEN RETURN 'done'; ELSE RETURN 'some'; END IF;
	WHEN 2 THEN
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review1_by IS NULL;
		IF FOUND THEN RETURN 'none'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review1_by = $1;
		IF NOT FOUND THEN RETURN 'gone'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review1_at IS NOT NULL;
		IF NOT FOUND THEN RETURN 'gogo'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review1_at IS NULL;
		IF NOT FOUND THEN RETURN 'done'; ELSE RETURN 'some'; END IF;
	WHEN 3 THEN
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review2_by IS NULL;
		IF FOUND THEN RETURN 'none'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review2_by = $1;
		IF NOT FOUND THEN RETURN 'gone'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review2_at IS NOT NULL;
		IF NOT FOUND THEN RETURN 'gogo'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND review2_at IS NULL;
		IF NOT FOUND THEN RETURN 'done'; ELSE RETURN 'some'; END IF;
	WHEN 9 THEN
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND final_by IS NULL;
		IF FOUND THEN RETURN 'none'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND final_by = $1;
		IF NOT FOUND THEN RETURN 'gone'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND final_at IS NOT NULL;
		IF NOT FOUND THEN RETURN 'gogo'; END IF;
		PERFORM 1 FROM words.translations WHERE id IN (SELECT * FROM unnest(tids)) AND final_at IS NULL;
		IF NOT FOUND THEN RETURN 'done'; ELSE RETURN 'some'; END IF;
	END CASE;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: books.id
CREATE OR REPLACE FUNCTION words.articles_for_book(integer,
	OUT sortid smallint,
	OUT translator_id smallint, OUT translator_name varchar(127),
	OUT review1_id smallint, OUT review1_name varchar(127),
	OUT review2_id smallint, OUT review2_name varchar(127),
	OUT final_id smallint, OUT final_name varchar(127),
	OUT title text, OUT body text)
RETURNS SETOF record AS $$
	SELECT c.sortid,
		t.translated_by AS translator_id,
		p0.name AS translator_name,
		t.review1_by AS review1_id,
		p1.name AS review1_name,
		t.review2_by AS review2_id,
		p2.name AS review2_name,
		t.final_by AS final_id,
		pf.name AS final_name,
		t.translation AS title,
		words.merge_article(c.article_id, b.lang) AS body
	FROM words.books b
	JOIN words.chapters c ON b.metabook_id = c.metabook_id
	JOIN words.translations t
		ON (c.title = t.sentence_code AND t.lang = b.lang)
	LEFT JOIN words.translators r0 ON t.translated_by = r0.id
	LEFT JOIN peeps.people p0 ON r0.person_id = p0.id
	LEFT JOIN words.translators r1 ON t.review1_by = r1.id
	LEFT JOIN peeps.people p1 ON r1.person_id = p1.id
	LEFT JOIN words.translators r2 ON t.review2_by = r2.id
	LEFT JOIN peeps.people p2 ON r2.person_id = p2.id
	LEFT JOIN words.translators rf ON t.final_by = rf.id
	LEFT JOIN peeps.people pf ON rf.person_id = pf.id
	WHERE b.id = $1
	ORDER BY c.sortid;
$$ LANGUAGE sql;


-- PARAMS: books.id but ONLY for my original English version
CREATE OR REPLACE FUNCTION words.articles_for_book_en(integer,
	OUT sortid smallint, OUT title text, OUT body text)
RETURNS SETOF record AS $$
	SELECT c.sortid,
		s.sentence as title,
		words.merge_article(c.article_id, 'en') AS body
	FROM words.books b
	JOIN words.chapters c ON b.metabook_id = c.metabook_id
	JOIN words.sentences s ON c.title = s.code
	WHERE b.id = $1 AND b.lang = 'en'
	ORDER BY c.sortid;
$$ LANGUAGE sql;


-- un-claim articles that were claimed but not started
CREATE OR REPLACE FUNCTION words.clear_claimed() RETURNS boolean AS $$
DECLARE
	aid smallint;
	tid smallint;
	anyfound boolean;
BEGIN
	anyfound := false;
	-- do exact same loop four times. this time = translated_
	FOR aid, tid IN
	SELECT DISTINCT words.article_for_xion(id), translated_by
	FROM words.translations
	WHERE (translated_by IS NOT NULL AND translated_at IS NULL)
	LOOP
		PERFORM 1 FROM words.translations WHERE id IN (
			SELECT * FROM words.tids_for_article_xor(aid, tid))
		AND translated_at IS NOT NULL;
		IF NOT FOUND THEN
			UPDATE words.translations
			SET translated_by = NULL
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor(aid, tid)
			);
			anyfound := true;
		END IF;
	END LOOP;
	-- do exact same loop four times. this time = review1_
	FOR aid, tid IN
	SELECT DISTINCT words.article_for_xion(id), review1_by
	FROM words.translations
	WHERE (review1_by IS NOT NULL AND review1_at IS NULL)
	LOOP
		PERFORM 1 FROM words.translations WHERE id IN (
			SELECT * FROM words.tids_for_article_xor(aid, tid))
		AND review1_at IS NOT NULL;
		IF NOT FOUND THEN
			UPDATE words.translations
			SET review1_by = NULL
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor(aid, tid)
			);
			anyfound := true;
		END IF;
	END LOOP;
	-- do exact same loop four times. this time = review2_
	FOR aid, tid IN
	SELECT DISTINCT words.article_for_xion(id), review2_by
	FROM words.translations
	WHERE (review2_by IS NOT NULL AND review2_at IS NULL)
	LOOP
		PERFORM 1 FROM words.translations WHERE id IN (
			SELECT * FROM words.tids_for_article_xor(aid, tid))
		AND review2_at IS NOT NULL;
		IF NOT FOUND THEN
			UPDATE words.translations
			SET review2_by = NULL
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor(aid, tid)
			);
			anyfound := true;
		END IF;
	END LOOP;
	-- do exact same loop four times. this time = final_
	FOR aid, tid IN
	SELECT DISTINCT words.article_for_xion(id), final_by
	FROM words.translations
	WHERE (final_by IS NOT NULL AND final_at IS NULL)
	LOOP
		PERFORM 1 FROM words.translations WHERE id IN (
			SELECT * FROM words.tids_for_article_xor(aid, tid))
		AND final_at IS NOT NULL;
		IF NOT FOUND THEN
			UPDATE words.translations
			SET final_by = NULL
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor(aid, tid)
			);
			anyfound := true;
		END IF;
	END LOOP;
	-- any found in any of the four loops?
	RETURN anyfound;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION words.clean_raw() RETURNS TRIGGER AS $$
BEGIN
	NEW.raw = replace(NEW.raw, E'\r', '');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_raw ON words.articles CASCADE;
CREATE TRIGGER clean_raw
	BEFORE INSERT OR UPDATE OF raw ON words.articles
	FOR EACH ROW EXECUTE PROCEDURE words.clean_raw();


CREATE OR REPLACE FUNCTION words.clean_template() RETURNS TRIGGER AS $$
BEGIN
	NEW.template = replace(NEW.template, E'\r', '');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_template ON words.articles CASCADE;
CREATE TRIGGER clean_template
	BEFORE INSERT OR UPDATE OF template ON words.articles
	FOR EACH ROW EXECUTE PROCEDURE words.clean_template();


CREATE OR REPLACE FUNCTION words.sentences_code_gen() RETURNS TRIGGER AS $$
BEGIN
	NEW.code = core.unique_for_table_field(8, 'words.sentences', 'code');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS sentences_code_gen ON words.sentences CASCADE;
CREATE TRIGGER sentences_code_gen
	BEFORE INSERT ON words.sentences
	FOR EACH ROW WHEN (NEW.code IS NULL)
	EXECUTE PROCEDURE words.sentences_code_gen();


-- the extra requirement for NEW.replacements to be empty is because
-- of database dump loading: it was overwriting already-done replacements
CREATE OR REPLACE FUNCTION words.make_replacements() RETURNS TRIGGER AS $$
BEGIN
	NEW.replacements = ARRAY(SELECT unnest(regexp_matches(NEW.sentence, E'<[^>]+>', 'g')));
	NEW.sentence = replace(NEW.sentence, NEW.replacements[1], '<');
	NEW.sentence = replace(NEW.sentence, NEW.replacements[2], '>');
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS make_replacements ON words.sentences CASCADE;
CREATE TRIGGER make_replacements
	BEFORE INSERT ON words.sentences
	FOR EACH ROW WHEN (
		NEW.sentence LIKE '%<%' AND (
			NEW.replacements IS NULL OR NEW.replacements = '{}'))
	EXECUTE PROCEDURE words.make_replacements();


-- Strip all line breaks and spaces around translation before storing
CREATE OR REPLACE FUNCTION words.clean_xion() RETURNS TRIGGER AS $$
BEGIN
	NEW.translation = btrim(regexp_replace(NEW.translation, '\s+', ' ', 'g'));
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS clean_xion ON words.translations CASCADE;
CREATE TRIGGER clean_xion
	BEFORE INSERT OR UPDATE OF translation ON words.translations
	FOR EACH ROW EXECUTE PROCEDURE words.clean_xion();


-- PARAMS: translators.id, metabooks.id
CREATE OR REPLACE FUNCTION words.assign_editor(integer, integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE words.translations
	SET final_by = $1
	WHERE sentence_code IN (
		SELECT code
		FROM words.sentences
		WHERE article_id IN (
			SELECT article_id
			FROM words.chapters
			WHERE metabook_id = $2))
	AND lang = (
		SELECT lang
		FROM words.translators
		WHERE id = $1)
	AND final_by IS NULL;
	status := 200;
	js := json_agg(r) FROM (
		SELECT id
		FROM words.translations
		WHERE final_by = $1
		ORDER BY id) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: translators.id, articles.id
CREATE OR REPLACE FUNCTION words.xor_get_article(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	role smallint;
	tlang char(2);
BEGIN
	role := words.xor_article_role($1, $2);
	IF role IS NULL THEN
		status := 404;
		js := '{}';
		RETURN;
	END IF;
	SELECT lang INTO tlang FROM words.translators WHERE id = $1;
	status := 200;
	js := row_to_json(r) FROM (
		SELECT id,
			role,
			words.xor_article_state($1, $2) AS state,
			filename,
			template,
			raw,
			words.merge_article($2, tlang) AS merged, (
			SELECT json_agg(ss) AS sentences FROM (
				SELECT t.id, (CASE
					WHEN role = 1 THEN translated_at
					WHEN role = 2 THEN review1_at
					WHEN role = 3 THEN review2_at
					WHEN role = 9 THEN final_at END) AS done_at,
					t.translated_by,
					t.translated_at,
					t.review1_by,
					t.review1_at,
					t.review2_by,
					t.review2_at,
					t.final_by,
					t.final_at,
					s.sortid,
					s.code,
					s.replacements,
					s.comment,
					s.sentence,
					t.translation AS raw,
					words.merge_replacements(translation, replacements) AS merged
				FROM words.sentences s
				JOIN words.translations t
					ON (s.code = t.sentence_code AND t.lang = tlang)
				WHERE s.article_id = $2
				ORDER BY s.sortid
			) ss)
		FROM words.articles
		WHERE id = $2
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: name, email, lang, role, expert
CREATE OR REPLACE FUNCTION words.add_candidate(text, text, char(2), char(3), char(3),
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	SELECT id INTO pid FROM peeps.person_create($1, $2);
	INSERT INTO words.candidates(person_id, lang, role, expert)
	VALUES (pid, $3, $4, $5);
	status := 200;
	js := json_build_object('person_id', pid);
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


CREATE OR REPLACE FUNCTION words.lang_count(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT lang,
		COUNT(CASE WHEN yesno IS NULL THEN 1 END) AS yn,
		COUNT(CASE WHEN yesno IS TRUE THEN 1 END) AS y,
		COUNT(CASE WHEN yesno IS FALSE THEN 1 END) AS n
		FROM words.candidates
		WHERE has_emailed IS TRUE
		GROUP BY lang ORDER BY lang
	) r;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION words.candidates_lang(char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT c.*, p.name
		FROM words.candidates c
		JOIN peeps.people p ON c.person_id = p.id
		WHERE lang = $1
		AND has_emailed IS TRUE
		ORDER BY c.yesno DESC, c.lang ASC, c.role ASC, c.expert DESC, c.id ASC
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: candidates.id, lang, role, expert, yesno, notes
CREATE OR REPLACE FUNCTION words.update_candidate(integer, char(2), char(3), char(3), boolean, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE words.candidates
	SET lang = $2,
		role = $3,
		expert = $4,
		yesno = $5,
		notes = $6
	WHERE id = $1;
	status := 200;
	js := json_build_object('id', $1);
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


-- PARAMS: candidates.id, lang
CREATE OR REPLACE FUNCTION words.update_candidate_lang(integer, char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE words.candidates SET lang = $2 WHERE id = $1;
	status := 200;
	js := json_build_object('id', $1);
END;
$$ LANGUAGE plpgsql;


-- PARAMS: candidates.id, notes
CREATE OR REPLACE FUNCTION words.update_candidate_notes(integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	UPDATE words.candidates SET notes = $2 WHERE id = $1;
	status := 200;
	js := json_build_object('id', $1);
END;
$$ LANGUAGE plpgsql;


-- PARAMS: candidates.id
CREATE OR REPLACE FUNCTION words.approve_candidate(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	UPDATE words.candidates SET yesno = TRUE
	WHERE id = $1
	RETURNING person_id INTO pid;
	status := 200;
	js := json_build_object('person_id', pid);
END;
$$ LANGUAGE plpgsql;


-- PARAMS: candidates.id
CREATE OR REPLACE FUNCTION words.reject_candidate(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	UPDATE words.candidates SET yesno = FALSE
	WHERE id = $1
	RETURNING person_id INTO pid;
	status := 200;
	js := json_build_object('person_id', pid);
END;
$$ LANGUAGE plpgsql;


-- PARAMS: candidates.id
CREATE OR REPLACE FUNCTION words.delete_candidate(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	pid integer;
BEGIN
	DELETE FROM words.candidates
	WHERE id = $1
	RETURNING person_id INTO pid;
	status := 200;
	js := json_build_object('person_id', pid);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION words.get_collections(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id, name
		FROM words.collections
		ORDER BY id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: collections.id
CREATE OR REPLACE FUNCTION words.get_collection(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id, filename
		FROM words.articles
		WHERE collection_id = $1
		ORDER BY id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION words.get_xors(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT t.*,
			p.name,
			p.email,
			p.public_id
		FROM words.translators t
		LEFT JOIN peeps.people p ON t.person_id = p.id
		ORDER BY t.lang, t.roll, t.id
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.get_xor(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT t.*,
			p.name,
			p.email,
			p.public_id,
		(SELECT json_agg(cl) AS collections FROM (
				SELECT c.id, c.name
				FROM words.coltranes t
				JOIN words.collections c ON t.collection_id = c.id
				WHERE translator_id = $1
		) cl),
		(SELECT json_agg(t1) AS translations FROM (
				SELECT t.id,
					t.translated_at AS finished,
					t.sentence_code,
					s.sentence,
					t.translation
				FROM words.translations t
				JOIN words.sentences s ON t.sentence_code = s.code
				WHERE t.translated_by = $1
				ORDER BY t.translated_at, t.id
		) t1),
		(SELECT json_agg(t2) AS review1s FROM (
				SELECT t.id,
				t.review1_at AS finished,
				t.sentence_code,
				s.sentence,
				t.translation
				FROM words.translations t
				JOIN words.sentences s ON t.sentence_code = s.code
				WHERE t.review1_by = $1
				ORDER BY t.review1_at, t.id
		) t2),
		(SELECT json_agg(t3) AS review2s FROM (
				SELECT t.id,
				t.review2_at AS finished,
				t.sentence_code,
				s.sentence,
				t.translation
				FROM words.translations t
				JOIN words.sentences s ON t.sentence_code = s.code
				WHERE t.review2_by = $1
				ORDER BY t.review2_at, t.id
		) t3),
		(SELECT json_agg(f) AS finals FROM (
				SELECT t.id,
				t.final_at AS finished,
				t.sentence_code,
				s.sentence,
				t.translation
				FROM words.translations t
				JOIN words.sentences s ON t.sentence_code = s.code
				WHERE t.final_by = $1
				ORDER BY t.final_at, t.id
		) f),
		(SELECT json_agg(qq) AS questions FROM (
				SELECT id, article_id, filename, sentence_code, sentence,
					translation_id, lang, translation, question, answer
				FROM words.question_view
				WHERE asked_by = $1
				ORDER BY id
		) qq),
		(SELECT json_agg(rr) AS replaced FROM (
				SELECT r.id, r.translation_id,
					r.translation AS old, t.translation AS new
				FROM words.replaced r
				JOIN words.translations t ON r.translation_id = t.id
				JOIN words.sentences s ON t.sentence_code = s.code
				WHERE r.replaced_by = $1
				ORDER BY r.id
		) rr)
		FROM words.translators t
		LEFT JOIN peeps.people p ON t.person_id = p.id
		WHERE t.id = $1
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS : translators.id, roll, notes
CREATE OR REPLACE FUNCTION words.update_xor(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE words.translators
	SET roll = $2, notes = $3
	WHERE id = $1;
	SELECT x.status, x.js
	INTO status, js
	FROM words.get_xor($1) x;
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
END
$$ LANGUAGE plpgsql;


-- PARAMS: person_id, lang
CREATE OR REPLACE FUNCTION words.add_xor(integer, char(2),
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	tid smallint;
BEGIN
	INSERT INTO words.translators(person_id, lang)
	VALUES ($1, $2)
	RETURNING id INTO tid;
	status := 200;
	js := row_to_json(r) FROM (
		SELECT *
		FROM words.translators
		WHERE id = tid) r;
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


-- assign collection to translator 
-- PARAMS: collections.id, translators.id
CREATE OR REPLACE FUNCTION words.assign_col_xor(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	-- if not found, add this collection-translator link
	PERFORM 1
	FROM words.coltranes
	WHERE collection_id = $1
	AND translator_id = $2;
	IF NOT FOUND THEN
		INSERT INTO words.coltranes(collection_id, translator_id)
		VALUES ($1, $2);
	END IF;
	status := 200;
	-- make sure collection has this translator's languages
	-- return translations.ids
	js := json_agg(r) FROM (
		SELECT id
		FROM words.init_collection_lang($1, (
				SELECT lang
				FROM words.translators
				WHERE id = $2
		)) id
	) r;
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


-- PARAMS: articles.id
CREATE OR REPLACE FUNCTION words.get_article(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT a.id,
			a.filename,
			json_build_object('id', c.id, 'name', c.name) AS collection,
			a.raw,
			a.template,
			(SELECT json_agg(ss) AS sentences FROM (
				SELECT code, sortid, sentence, replacements, comment
				FROM words.sentences
				WHERE article_id = a.id
				ORDER BY sortid
			) ss)
		FROM words.articles a
		JOIN words.collections c ON a.collection_id = c.id
		WHERE a.id = $1
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: articles.id, raw
CREATE OR REPLACE FUNCTION words.update_article_raw(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE words.articles
	SET raw = $2
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js
	FROM words.get_article($1) x;
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


-- PARAMS: articles.id, template
CREATE OR REPLACE FUNCTION words.update_article_template(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE words.articles
	SET template = $2
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js
	FROM words.get_article($1) x;
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


-- Full complete representation of an article, with all parts that might be used to edit.
-- id, filename, template, raw, merged, sentences: [{sortid, code, replacements, raw, merged}]
-- PARAMS: article_id, lang
CREATE OR REPLACE FUNCTION words.get_article_lang(integer, char(2),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	-- English comes directly from sentences.sentence not translations.translation
	IF $2 = 'en' THEN js := row_to_json(r) FROM (
		SELECT id,
			filename,
			template,
			raw,
			words.merge_article($1, $2) AS merged, (
			SELECT json_agg(s) AS sentences FROM (
				SELECT sortid,
					code,
					replacements,
					sentence AS raw,
					words.merge_replacements(sentence, replacements) AS merged
				FROM words.sentences 
				WHERE article_id = $1
				ORDER BY sortid
			) s)
		FROM words.articles
		WHERE id = $1
	) r;
	-- Everything but English is in translations table
	ELSE js := row_to_json(r) FROM (
		SELECT id,
			filename,
			template,
			raw,
			words.merge_article($1, $2) AS merged, (
			SELECT json_agg(s) AS sentences FROM (
				SELECT t.id,
					s.sortid,
					s.code,
					s.replacements,
					t.translation AS raw,
					words.merge_replacements(translation, replacements) AS merged
				FROM words.sentences s
				JOIN words.translations t
					ON (s.code = t.sentence_code AND t.lang = $2)
				WHERE s.article_id = $1
				ORDER BY s.sortid
			) s)
		FROM words.articles
		WHERE id = $1
	) r;
	END IF;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: code
CREATE OR REPLACE FUNCTION words.get_sentence(char(8),
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := row_to_json(r) FROM (
		SELECT s.code,
			s.article_id,
			a.filename,
			s.sortid,
			s.sentence,
			s.replacements,
			s.comment, (
				SELECT json_agg(tt) AS translations
				FROM (
					SELECT t.id, lang, translation
					FROM words.translations t
					WHERE t.sentence_code = s.code
					ORDER BY t.id
				) tt
			)
		FROM words.sentences s
		JOIN words.articles a ON s.article_id = a.id
		WHERE s.code = $1
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS : code, comment
CREATE OR REPLACE FUNCTION words.update_sentence_comment(char(8), text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE words.sentences
	SET comment = $2
	WHERE code = $1;
	status := 200;
	js := '{}';
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
END
$$ LANGUAGE plpgsql;


-- PARAMS: translation_id
CREATE OR REPLACE FUNCTION words.get_xion(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	js := row_to_json(r) FROM (
		SELECT t.id,
		s.article_id,
		a.filename,
		t.sentence_code,
		t.lang,
		s.sentence,
		words.merge_replacements(s.sentence, s.replacements) AS s2,
		t.translation,
		words.merge_replacements(t.translation, s.replacements) AS t2,
		t.translated_at, (
			SELECT row_to_json(tr) AS translator FROM (
				SELECT r.id,
				r.person_id,
				p.name
				FROM words.translators r
				JOIN peeps.people p ON r.person_id = p.id
				WHERE r.id = t.translated_by
			) tr),
		t.review1_at, (
			SELECT row_to_json(r1) AS reviewer1 FROM (
				SELECT r.id,
				r.person_id,
				p.name
				FROM words.translators r
				JOIN peeps.people p ON r.person_id = p.id
				WHERE r.id = t.review1_by
			) r1),
		t.review2_at, (
			SELECT row_to_json(r2) AS reviewer2 FROM (
				SELECT r.id,
				r.person_id,
				p.name
				FROM words.translators r
				JOIN peeps.people p ON r.person_id = p.id
				WHERE r.id = t.review2_by
			) r2),
		t.final_at, (
			SELECT row_to_json(f) AS editor FROM (
				SELECT r.id,
				r.person_id,
				p.name
				FROM words.translators r
				JOIN peeps.people p ON r.person_id = p.id
				WHERE r.id = t.final_by
			) f),
		(SELECT json_agg(rp) AS replaced FROM (
			SELECT id, replaced_by, translation
			FROM words.replaced
			WHERE translation_id = $1
			ORDER BY id
		) rp),
		(SELECT json_agg(q) AS questions FROM (
			SELECT id, asked_by, created_at, question, answer
			FROM words.questions
			WHERE translation_id = $1
			ORDER BY id
		) q)
		FROM words.translations t
		JOIN words.sentences s ON t.sentence_code = s.code
		JOIN words.articles a ON s.article_id = a.id
		WHERE t.id = $1
	) r;
	IF js IS NULL THEN
		status := 404;
		js := '{}';
	END IF;
	status := 200;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: translation_id, text. CAREFUL! For admin only, not translator
CREATE OR REPLACE FUNCTION words.admin_update_xion(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	UPDATE words.translations
	SET translation = $2
	WHERE id = $1;
	SELECT x.status, x.js INTO status, js
	FROM words.get_xion($1) x;
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


-- PARAMS: translator_id, translation_id, text
CREATE OR REPLACE FUNCTION words.xor_update_xion(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	role smallint;
	old_translation text;
BEGIN
	role := words.xor_xion_role($1, $2);
	-- stop unless translator has permission for this translation
	IF role IS NULL THEN
		status := 403;
		js := '{"error":"not yours"}';
		RETURN;
	END IF;
	-- if their role _at is not null, no more changes (see "unfinish" action)
	CASE role
		WHEN 1 THEN
			PERFORM 1 FROM words.translations
			WHERE id = $2 AND translated_at IS NOT NULL;
		WHEN 2 THEN
			PERFORM 1 FROM words.translations
			WHERE id = $2 AND review1_at IS NOT NULL;
		WHEN 3 THEN
			PERFORM 1 FROM words.translations
			WHERE id = $2 AND review2_at IS NOT NULL;
	END CASE;
	IF FOUND THEN  -- from query inside CASE role
		status := 403;
		js := '{"error":"no update: finished"}';
		RETURN;
	END IF;
	-- if translated_at is not null, then save what we are replacing
	SELECT translation INTO old_translation
	FROM words.translations
	WHERE id = $2
	AND translated_at IS NOT NULL;
	-- ... but only if new translation is different than old one
	IF FOUND AND old_translation != $3 THEN
		INSERT INTO words.replaced
			(translation_id, replaced_by, translation)
		SELECT id, $1, translation
		FROM words.translations
		WHERE id = $2;
	END IF;
	UPDATE words.translations
	SET translation = $3
	WHERE id = $2;
	SELECT x.status, x.js INTO status, js
	FROM words.get_xion($2) x;
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


-- PARAMS: translator_id, translation_id
CREATE OR REPLACE FUNCTION words.xor_finish_xion(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	role smallint;
BEGIN
	role := words.xor_xion_role($1, $2);
	-- stop unless translator has permission for this translation
	IF role IS NULL THEN
		status := 403;
		js := '{"error":"not yours"}';
		RETURN;
	END IF;
	-- stop if translation is null
	PERFORM 1
	FROM words.translations
	WHERE id = $2
	AND translation IS NULL;
	IF FOUND THEN
		status := 403;
		js := '{"error":"translation is null"}';
		RETURN;
	END IF;
	-- pick which field to mark based on their role
	CASE role
		WHEN 1 THEN
			UPDATE words.translations
			SET translated_at = NOW()
			WHERE id = $2;
		WHEN 2 THEN
			UPDATE words.translations
			SET review1_at = NOW()
			WHERE id = $2;
		WHEN 3 THEN
			UPDATE words.translations
			SET review2_at = NOW()
			WHERE id = $2;
	END CASE;
	SELECT x.status, x.js INTO status, js
	FROM words.get_xion($2) x;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: translator_id, translation_id
CREATE OR REPLACE FUNCTION words.xor_unfinish_xion(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	role smallint;
BEGIN
	role := words.xor_xion_role($1, $2);
	-- stop unless translator has permission for this translation
	IF role IS NULL THEN
		status := 403;
		js := '{"error":"not yours"}';
		RETURN;
	END IF;
	-- pick which field to mark based on their role
	CASE role
		WHEN 1 THEN
			UPDATE words.translations
			SET translated_at = NULL
			WHERE id = $2;
		WHEN 2 THEN
			UPDATE words.translations
			SET review1_at = NULL
			WHERE id = $2;
		WHEN 3 THEN
			UPDATE words.translations
			SET review2_at = NULL
			WHERE id = $2;
	END CASE;
	SELECT x.status, x.js INTO status, js
	FROM words.get_xion($2) x;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: translator_id, translation_id, question
CREATE OR REPLACE FUNCTION words.ask_question(integer, integer, text,
	OUT status smallint, OUT js json) AS $$
BEGIN
	-- stop unless translator has permission for this translation
	IF words.xor_xion_role($1, $2) IS NULL THEN
		status := 403;
		js := '{"error":"not yours"}';
	ELSE
		INSERT INTO words.questions
			(translation_id, asked_by, question)
		VALUES ($2, $1, $3);
		status := 200;
		js := '{}';
	END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION words.unanswered_questions(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT * FROM words.question_view
		WHERE answer IS NULL
	) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: questions.id, myreply
CREATE OR REPLACE FUNCTION words.answer_question(integer, text,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	ques text;
	ence text;
	tion text;
	aid integer;
	pid integer;
	eid integer;
BEGIN
	-- pid=person_id, ques=question, ence=sentence, tion=translation, aid=article_id
	SELECT r.person_id, q.question, s.sentence, t.translation, s.article_id
		INTO pid, ques, ence, tion, aid
	FROM words.questions q
	JOIN words.translations t ON q.translation_id = t.id
	JOIN words.sentences s ON t.sentence_code = s.code
	JOIN words.translators r ON q.asked_by = r.id
	WHERE q.id = $1;
	UPDATE words.questions SET answer = $2 WHERE id = $1;
	-- PARAMS: emailer_id, person_id, profile, category, subject, body, reference_id (NULL unless reply)
	SELECT * INTO eid FROM peeps.outgoing_email(1, pid, 'sivers', 'sivers',
		CONCAT('your translation question [', $1, ']'),
		CONCAT('ARTICLE: https://tr.sivers.org/article/', aid, E'\n',
			'SENTENCE: ', ence, E'\n',
			'TRANSLATION: ', tion, E'\n',
			'YOUR QUESTION: ', ques, E'\n',
			'MY REPLY: ', E'\n\n', $2),
		NULL
	);
	status := 200;
	js := json_build_object('email_id', eid);
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


-- PARAMS: candidates.id
CREATE OR REPLACE FUNCTION words.hire_candidate(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	tid smallint;
BEGIN
	INSERT INTO words.translators(person_id, lang, roll, notes)
	SELECT person_id, lang,
		SUBSTRING(role, 1, 1)::smallint,
		CONCAT(
		role, ': ',
		expert, ': ',
		trim(replace(regexp_replace(notes, E'[\r\n\t]', ' ', 'g'), '  ', ' ')))
	FROM words.candidates
	WHERE id = $1
	RETURNING id INTO tid;
	DELETE FROM words.candidates
	WHERE id = $1;
	status := 200;
	js := row_to_json(r) FROM (
		SELECT *
		FROM words.translators
		WHERE id = tid) r;
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


-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.unhire_xor(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
	cid smallint;
BEGIN
	INSERT INTO words.candidates(person_id, lang, role, expert, yesno, has_emailed, notes)
	SELECT person_id, lang, 'zzz', 'zzz', false, true, 'removed from translators for doing nothing'
	FROM words.translators
	WHERE id = $1
	RETURNING id INTO cid;
	DELETE FROM words.coltranes WHERE translator_id = $1;
	DELETE FROM words.translators WHERE id = $1;
	status := 200;
	js := row_to_json(r) FROM (
		SELECT *
		FROM words.candidates
		WHERE id = cid) r;
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


-- list of articles grouped for translator
-- PARAMS: translators.id
CREATE OR REPLACE FUNCTION words.xor_articles(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	rol smallint;
BEGIN
	SELECT roll INTO rol FROM words.translators WHERE id = $1;
	IF rol = 9 THEN
		js := json_build_object(
		'do', (
			SELECT json_agg(d1) FROM (
				SELECT a.id, a.filename
				FROM words.chapters c
				JOIN words.articles a ON c.article_id = a.id
				WHERE a.id IN (
					SELECT * FROM words.articles_xor_state($1, 'do')
				) ORDER BY c.sortid
			) d1),
		'done', (
			SELECT json_agg(d2) FROM (
				SELECT a.id, a.filename
				FROM words.chapters c
				JOIN words.articles a ON c.article_id = a.id
				WHERE a.id IN (
					SELECT * FROM words.articles_xor_state($1, 'done')
				) ORDER BY c.sortid
			) d2)
		);
	ELSE
		js := json_build_object(
		'do', (
			SELECT json_agg(a) FROM (
				SELECT id, filename FROM words.articles WHERE id IN (
					SELECT * FROM words.articles_xor_state($1, 'do')
				) ORDER BY id
			) a),
		'claim', (
			SELECT json_agg(b) FROM (
				SELECT id, filename FROM words.articles WHERE id IN (
					SELECT * FROM words.articles_xor_state($1, 'claim')
				) ORDER BY RANDOM()
			) b),
		'wait', (
			SELECT json_agg(b) FROM (
				SELECT id, filename FROM words.articles WHERE id IN (
					SELECT * FROM words.articles_xor_state($1, 'wait')
				) ORDER BY RANDOM()
			) b),
		'done', (
			SELECT json_agg(c) FROM (
				SELECT id, filename FROM words.articles WHERE id IN (
					SELECT * FROM words.articles_xor_state($1, 'done')
				) ORDER BY id DESC
			) c)
		);
	END IF;
	status := 200;
END;
$$ LANGUAGE plpgsql;


-- translator wants to claim this article  (no response if success)
-- PARAMS: translators.id, articles.id
CREATE OR REPLACE FUNCTION words.xor_claim_article(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	role smallint;
err_code text;
	err_msg text;
	err_detail text;
	err_context text;
BEGIN
	-- refuse if they have other articles unfinished
	PERFORM 1 FROM words.articles_xor_state($1, 'do');
	IF FOUND THEN RAISE 'finish others first'; END IF;
	-- refuse unless in list of articles with 'claim' state
	PERFORM 1 FROM words.articles_xor_state($1, 'claim') x WHERE x = $2;
	IF NOT FOUND THEN RAISE 'you can not claim'; END IF;
	-- ok 
	SELECT * INTO role FROM words.xor_article_role($1, $2);
	CASE role
		WHEN 1 THEN
			UPDATE words.translations
			SET translated_by = $1
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor($2, $1));
		WHEN 2 THEN
			UPDATE words.translations
			SET review1_by = $1
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor($2, $1));
		WHEN 3 THEN
			UPDATE words.translations
			SET review2_by = $1
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor($2, $1));
		WHEN 9 THEN
			UPDATE words.translations
			SET final_by = $1
			WHERE id IN (
				SELECT * FROM words.tids_for_article_xor($2, $1));
	END CASE;
	status := 200;
	js := '{}';
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


-- PARAMS: collections.id
-- returns lang t_done t_claim r1_done r1_claim r2_done r2_claim
CREATE OR REPLACE FUNCTION words.collection_progress(integer,
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		WITH tx AS (
			SELECT lang,
				translated_by, translated_at,
				review1_by, review1_at,
				review2_by, review2_at,
				final_by, final_at
			FROM words.translations
			WHERE sentence_code IN (
				SELECT code FROM words.sentences
				WHERE article_id IN (
					SELECT id FROM words.articles
					WHERE collection_id = $1))
		)
		SELECT y.lang,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND translated_at IS NOT NULL) AS t_done,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND translated_by IS NOT NULL) AS t_claim,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND review1_at IS NOT NULL) AS r1_done,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND review1_by IS NOT NULL) AS r1_claim,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND review2_at IS NOT NULL) AS r2_done,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND review2_by IS NOT NULL) AS r2_claim,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND final_at IS NOT NULL) AS f_done,
		(SELECT COUNT(*) FROM tx WHERE tx.lang=y.lang AND final_by IS NOT NULL) AS f_claim
		FROM tx y
		GROUP BY y.lang
		ORDER BY t_done DESC, r1_done DESC, r2_done DESC, f_done DESC, lang ASC
	) r;
	IF js IS NULL THEN
		js := '[]';
	END IF;
END;
$$ LANGUAGE plpgsql;


-- PARAMS: books.id
-- id, metabook_id, lang, title, subtitle, chapters: [{num, title, body}]
CREATE OR REPLACE FUNCTION words.get_book(integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	whatlang char(2);
BEGIN
	SELECT lang INTO whatlang FROM words.books WHERE id = $1;
	IF whatlang = 'en' THEN
		js := row_to_json(r) FROM (
			SELECT id, metabook_id, lang, title, subtitle,
			(SELECT json_agg(ch) AS chapters FROM (
				SELECT c.sortid AS num,
					s.sentence AS title,
					a.raw AS body
				FROM words.books b
				JOIN words.chapters c ON b.metabook_id = c.metabook_id
				JOIN words.articles a ON c.article_id = a.id
				JOIN words.sentences s ON c.title = s.code
				WHERE b.id = $1
				AND c.sortid IS NOT NULL
				ORDER BY c.sortid
			) ch)
			FROM words.books
			WHERE id = $1
		) r;
	ELSE
		js := row_to_json(r) FROM (
			SELECT id, metabook_id, lang, title, subtitle,
			(SELECT json_agg(ch) AS chapters FROM (
				SELECT c.sortid AS num,
					t.translation AS title,
					words.merge_article(c.article_id, b.lang) AS body
				FROM words.books b
				JOIN words.chapters c ON b.metabook_id = c.metabook_id
				JOIN words.translations t
					ON (c.title = t.sentence_code AND t.lang = b.lang)
				WHERE b.id = $1
				AND c.sortid IS NOT NULL
				ORDER BY c.sortid
			) ch)
			FROM words.books
			WHERE id = $1
		) r;
	END IF;
	IF js IS NULL THEN js := '[]'; END IF;
	status := 200;
END;
$$ LANGUAGE plpgsql;


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


-- use to un-claim an article from a translator that has done just
-- one or two lines, long ago, and has clearly abandoned it.
-- PARAMS: translations.id, translators.id
CREATE OR REPLACE FUNCTION words.unclaim_article_xion_xor(integer, integer,
	OUT status smallint, OUT js json) AS $$
DECLARE
	article_id integer;
BEGIN
	article_id := words.article_for_xion($1);
	-- only one of these three updates will match, either translated_
	UPDATE words.translations
	SET translated_by = NULL, translated_at = NULL
	WHERE id IN (
		SELECT * FROM words.tids_for_article_xor(article_id, $2))
	AND translated_by = $2;
	-- .. or review1_
	UPDATE words.translations
	SET review1_by = NULL, review1_at = NULL
	WHERE id IN (
		SELECT * FROM words.tids_for_article_xor(article_id, $2))
	AND review1_by = $2;
	-- .. or review2_
	UPDATE words.translations
	SET review2_by = NULL, review2_at = NULL
	WHERE id IN (
		SELECT * FROM words.tids_for_article_xor(article_id, $2))
	AND review2_by = $2;
	-- .. or final_
	UPDATE words.translations
	SET final_by = NULL, final_at = NULL
	WHERE id IN (
		SELECT * FROM words.tids_for_article_xor(article_id, $2))
	AND final_by = $2;
	status := 200;
	js := '{}';
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION words.mismatched_tags(
	OUT status smallint, OUT js json) AS $$
BEGIN
	status := 200;
	js := json_agg(r) FROM (
		SELECT id, code, sentence, translation, lang, translated_by, review1_by FROM (
			SELECT t.id, t.lang, translation, translated_by, review1_by,
			(SELECT COUNT(*) FROM regexp_matches(translation, E'[<>]', 'g')) AS tx,
			s.code, sentence,
			(SELECT COUNT(*) FROM regexp_matches(sentence, E'[<>]', 'g')) AS sx
			FROM words.translations t
			JOIN words.sentences s ON t.sentence_code=s.code
			WHERE translation IS NOT NULL
			AND (sentence LIKE '%<%' OR sentence LIKE '%>%')
			AND t.id > 5000
		) tt
		WHERE tx != sx
		ORDER BY id) r;
	IF js IS NULL THEN js := '[]'; END IF;
END;
$$ LANGUAGE plpgsql;


COMMIT;


