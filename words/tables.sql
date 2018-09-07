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

