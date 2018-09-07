--
-- PostgreSQL database dump
--

-- Dumped from database version 10.4
-- Dumped by pg_dump version 10.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: collections; Type: TABLE DATA; Schema: words; Owner: d50b
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE words.collections DISABLE TRIGGER ALL;

INSERT INTO words.collections (id, name) VALUES (1, 'collection1');
INSERT INTO words.collections (id, name) VALUES (2, 'collection2');


ALTER TABLE words.collections ENABLE TRIGGER ALL;

--
-- Data for Name: articles; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.articles DISABLE TRIGGER ALL;

INSERT INTO words.articles (id, collection_id, filename, raw, template) VALUES (1, 1, 'finished', '<!-- headline here -->
<p>
	Some <strong>bold words</strong>.
	Now <a href="/">linked and <em>italic</em> words</a>.
	See <a href="/about">about</a> <a href="/">this</a>?
</p>', '<!-- {aaaaaaaa} -->
<p>
	{aaaaaaab}
	{aaaaaaac}
	{aaaaaaad}
</p>');
INSERT INTO words.articles (id, collection_id, filename, raw, template) VALUES (2, 1, 'unfinished', '<h1>hello</h1><p>not done yet</p>', '<h1>{bbbbbbbb}</h1><p>{bbbbbbbc}</p>');
INSERT INTO words.articles (id, collection_id, filename, raw, template) VALUES (3, 2, 'secret', '<!-- unannounced -->
<h1>
	This is secret
</h1>', '<!-- {cccccccc} -->
<h1>
{cccccccd}
</h1>');


ALTER TABLE words.articles ENABLE TRIGGER ALL;

--
-- Data for Name: sentences; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.sentences DISABLE TRIGGER ALL;

INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('aaaaaaaa', 1, 1, 'headline here', '{}', NULL);
INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('aaaaaaab', 1, 2, 'Some <bold words>.', '{<strong>,</strong>}', NULL);
INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('aaaaaaac', 1, 3, 'Now <linked and <italic> words>.', '{"<a href=\"/\">",<em>,</em>,</a>}', NULL);
INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('aaaaaaad', 1, 4, 'See <about> <this>?', '{"<a href=\"/about\">",</a>,"<a href=\"/\">",</a>}', NULL);
INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('bbbbbbbb', 2, 1, 'hello', '{}', 'to friends');
INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('bbbbbbbc', 2, 2, 'not done yet', '{}', NULL);
INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('cccccccc', 3, 1, 'unannounced', '{}', NULL);
INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('cccccccd', 3, 2, 'This is secret', '{}', NULL);
INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('mmmmmmmm', NULL, NULL, 'Start', '{}', NULL);
INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('nnnnnnnn', NULL, NULL, 'Finish', '{}', NULL);
INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('oooooooo', NULL, NULL, 'Moon', '{}', NULL);
INSERT INTO words.sentences (code, article_id, sortid, sentence, replacements, comment) VALUES ('pppppppp', NULL, NULL, 'Water', '{}', NULL);


ALTER TABLE words.sentences ENABLE TRIGGER ALL;

--
-- Data for Name: metabooks; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.metabooks DISABLE TRIGGER ALL;

INSERT INTO words.metabooks (id, title, title_code, subtitle, subtitle_code) VALUES (1, 'Moon', NULL, 'Water', NULL);


ALTER TABLE words.metabooks ENABLE TRIGGER ALL;

--
-- Data for Name: translators; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.translators DISABLE TRIGGER ALL;

INSERT INTO words.translators (id, person_id, lang, roll, notes) VALUES (1, 7, 'zh', 1, 'Gong finished article1 + 1st sentence of article2 + started 2nd sentence');
INSERT INTO words.translators (id, person_id, lang, roll, notes) VALUES (2, 5, 'zh', 2, 'Oompa review1ed article1 except last sentence only started');
INSERT INTO words.translators (id, person_id, lang, roll, notes) VALUES (3, 6, 'fr', 1, 'Augustus finished article1 + 1st sentence of article2');
INSERT INTO words.translators (id, person_id, lang, roll, notes) VALUES (4, 4, 'fr', 2, 'Charlie review1ed article1');
INSERT INTO words.translators (id, person_id, lang, roll, notes) VALUES (5, 3, 'es', 1, 'Veruca finished article1 + 1st sentence of article2');
INSERT INTO words.translators (id, person_id, lang, roll, notes) VALUES (6, 2, 'pt', 1, 'Willy almost finished article1 but has question on last sentence:15. Has not claimed article2.');
INSERT INTO words.translators (id, person_id, lang, roll, notes) VALUES (7, 8, 'ja', 1, 'Yoko just began. Assigned collection1 but has not claimed.');


ALTER TABLE words.translators ENABLE TRIGGER ALL;

--
-- Data for Name: translations; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.translations DISABLE TRIGGER ALL;

INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (21, 'bbbbbbbc', 'zh', 1, NULL, NULL, NULL, NULL, NULL, '还没做完');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (24, 'bbbbbbbc', 'pt', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (16, 'aaaaaaad', 'zh', 1, '2018-07-01 00:00:00+12', 2, NULL, NULL, NULL, '<到><这个>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (1, 'aaaaaaaa', 'es', 5, '2018-07-01 00:00:00+12', NULL, NULL, NULL, NULL, 'título aquí');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (3, 'aaaaaaaa', 'pt', 6, '2018-07-01 00:00:00+12', NULL, NULL, NULL, NULL, 'headline aqui');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (5, 'aaaaaaab', 'es', 5, '2018-07-01 00:00:00+12', NULL, NULL, NULL, NULL, 'algunas <palabras en negrita>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (7, 'aaaaaaab', 'pt', 6, '2018-07-01 00:00:00+12', NULL, NULL, NULL, NULL, 'algumas <palavras em negrito>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (9, 'aaaaaaac', 'es', 5, '2018-07-01 00:00:00+12', NULL, NULL, NULL, NULL, 'ahora <ligado y las <palabras en cursiva>>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (11, 'aaaaaaac', 'pt', 6, '2018-07-01 00:00:00+12', NULL, NULL, NULL, NULL, 'agora <ligados e as palavras em <itálico>>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (13, 'aaaaaaad', 'es', 5, '2018-07-01 00:00:00+12', NULL, NULL, NULL, NULL, 'conocer <de> <este>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (17, 'bbbbbbbb', 'es', 5, '2018-07-01 00:00:00+12', NULL, NULL, NULL, NULL, 'hola');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (20, 'bbbbbbbb', 'zh', 1, '2018-07-01 00:00:00+12', NULL, NULL, NULL, NULL, '你好');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (18, 'bbbbbbbb', 'fr', 3, '2018-07-01 00:00:00+12', NULL, NULL, NULL, NULL, 'bonjour');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (15, 'aaaaaaad', 'pt', 6, NULL, NULL, NULL, NULL, NULL, 'ver <sobre> <este>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (4, 'aaaaaaaa', 'zh', 1, '2018-07-01 00:00:00+12', 2, '2018-07-02 00:00:00+12', NULL, NULL, '这里头条');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (8, 'aaaaaaab', 'zh', 1, '2018-07-01 00:00:00+12', 2, '2018-07-02 00:00:00+12', NULL, NULL, '一些大<胆的话>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (12, 'aaaaaaac', 'zh', 1, '2018-07-01 00:00:00+12', 2, '2018-07-02 00:00:00+12', NULL, NULL, '在<联和<斜体>字>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (2, 'aaaaaaaa', 'fr', 3, '2018-07-01 00:00:00+12', 4, '2018-07-02 00:00:00+12', NULL, NULL, 'titre ici');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (6, 'aaaaaaab', 'fr', 3, '2018-07-01 00:00:00+12', 4, '2018-07-02 00:00:00+12', NULL, NULL, 'quelques <mots en gras>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (10, 'aaaaaaac', 'fr', 3, '2018-07-01 00:00:00+12', 4, '2018-07-02 00:00:00+12', NULL, NULL, 'maintenant <liés et mots <italiques>>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (14, 'aaaaaaad', 'fr', 3, '2018-07-01 00:00:00+12', 4, '2018-07-02 00:00:00+12', NULL, NULL, 'voir <à ce> <sujet>');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (25, 'aaaaaaaa', 'ja', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (26, 'aaaaaaab', 'ja', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (27, 'aaaaaaac', 'ja', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (28, 'aaaaaaad', 'ja', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (29, 'bbbbbbbb', 'ja', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (30, 'bbbbbbbc', 'ja', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (23, 'bbbbbbbc', 'fr', 3, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (19, 'bbbbbbbb', 'pt', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (22, 'bbbbbbbc', 'es', 5, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (31, 'oooooooo', 'pt', NULL, NULL, NULL, NULL, NULL, NULL, 'Lua');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (32, 'pppppppp', 'pt', NULL, NULL, NULL, NULL, NULL, NULL, 'Agua');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (33, 'oooooooo', 'zh', NULL, NULL, NULL, NULL, NULL, NULL, '月');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (34, 'pppppppp', 'zh', NULL, NULL, NULL, NULL, NULL, NULL, '水');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (35, 'mmmmmmmm', 'pt', NULL, NULL, NULL, NULL, NULL, NULL, 'Começar');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (36, 'mmmmmmmm', 'zh', NULL, NULL, NULL, NULL, NULL, NULL, '开始');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (37, 'nnnnnnnn', 'pt', NULL, NULL, NULL, NULL, NULL, NULL, 'Terminar');
INSERT INTO words.translations (id, sentence_code, lang, translated_by, translated_at, review1_by, review1_at, review2_by, review2_at, translation) VALUES (38, 'nnnnnnnn', 'zt', NULL, NULL, NULL, NULL, NULL, NULL, '完');


ALTER TABLE words.translations ENABLE TRIGGER ALL;

--
-- Data for Name: books; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.books DISABLE TRIGGER ALL;

INSERT INTO words.books (id, metabook_id, lang, title, title_translation, subtitle, subtitle_translation) VALUES (1, 1, 'en', 'Moon', NULL, 'Water', NULL);
INSERT INTO words.books (id, metabook_id, lang, title, title_translation, subtitle, subtitle_translation) VALUES (2, 1, 'pt', 'Lua', 31, 'Agua', 32);
INSERT INTO words.books (id, metabook_id, lang, title, title_translation, subtitle, subtitle_translation) VALUES (3, 1, 'zh', '月', 33, '水', 34);


ALTER TABLE words.books ENABLE TRIGGER ALL;

--
-- Data for Name: book_formats; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.book_formats DISABLE TRIGGER ALL;

INSERT INTO words.book_formats (id, book_id, format, isbn) VALUES (1, 1, 'epub', '0102030405060');
INSERT INTO words.book_formats (id, book_id, format, isbn) VALUES (2, 1, 'pdf', '0102030405061');
INSERT INTO words.book_formats (id, book_id, format, isbn) VALUES (3, 1, 'hard', '0102030405062');
INSERT INTO words.book_formats (id, book_id, format, isbn) VALUES (4, 2, 'epub', '0102030405070');
INSERT INTO words.book_formats (id, book_id, format, isbn) VALUES (5, 2, 'pdf', '0102030405071');
INSERT INTO words.book_formats (id, book_id, format, isbn) VALUES (6, 3, 'epub', '0102030405080');
INSERT INTO words.book_formats (id, book_id, format, isbn) VALUES (7, 3, 'pdf', '0102030405081');


ALTER TABLE words.book_formats ENABLE TRIGGER ALL;

--
-- Data for Name: candidates; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.candidates DISABLE TRIGGER ALL;

INSERT INTO words.candidates (id, person_id, created_at, lang, role, expert, yesno, has_emailed, notes) VALUES (1, 1, '2018-07-09', 'eo', '1st', 'hob', true, true, 'I will try');


ALTER TABLE words.candidates ENABLE TRIGGER ALL;

--
-- Data for Name: chapters; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.chapters DISABLE TRIGGER ALL;

INSERT INTO words.chapters (metabook_id, article_id, sortid, title) VALUES (1, 1, 1, 'mmmmmmmm');
INSERT INTO words.chapters (metabook_id, article_id, sortid, title) VALUES (1, 2, 2, 'nnnnnnnn');


ALTER TABLE words.chapters ENABLE TRIGGER ALL;

--
-- Data for Name: coltranes; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.coltranes DISABLE TRIGGER ALL;

INSERT INTO words.coltranes (collection_id, translator_id, role) VALUES (1, 1, 1);
INSERT INTO words.coltranes (collection_id, translator_id, role) VALUES (1, 2, 2);
INSERT INTO words.coltranes (collection_id, translator_id, role) VALUES (1, 3, 1);
INSERT INTO words.coltranes (collection_id, translator_id, role) VALUES (1, 4, 2);
INSERT INTO words.coltranes (collection_id, translator_id, role) VALUES (1, 5, 1);
INSERT INTO words.coltranes (collection_id, translator_id, role) VALUES (1, 6, 1);
INSERT INTO words.coltranes (collection_id, translator_id, role) VALUES (1, 7, 1);


ALTER TABLE words.coltranes ENABLE TRIGGER ALL;

--
-- Data for Name: questions; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.questions DISABLE TRIGGER ALL;

INSERT INTO words.questions (id, translation_id, asked_by, created_at, question, answer) VALUES (1, 15, 6, '2018-07-02', 'ver?', NULL);


ALTER TABLE words.questions ENABLE TRIGGER ALL;

--
-- Data for Name: replaced; Type: TABLE DATA; Schema: words; Owner: d50b
--

ALTER TABLE words.replaced DISABLE TRIGGER ALL;

INSERT INTO words.replaced (id, translation_id, replaced_by, translation) VALUES (1, 2, 4, 'tête ici');


ALTER TABLE words.replaced ENABLE TRIGGER ALL;

--
-- Name: articles_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('words.articles_id_seq', 3, true);


--
-- Name: book_formats_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('words.book_formats_id_seq', 7, true);


--
-- Name: books_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('words.books_id_seq', 3, true);


--
-- Name: candidates_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('words.candidates_id_seq', 2, false);


--
-- Name: collections_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('words.collections_id_seq', 3, true);


--
-- Name: metabooks_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('words.metabooks_id_seq', 2, true);


--
-- Name: questions_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('words.questions_id_seq', 1, true);


--
-- Name: replaced_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('words.replaced_id_seq', 2, false);


--
-- Name: translations_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('words.translations_id_seq', 39, true);


--
-- Name: translators_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('words.translators_id_seq', 7, true);


--
-- PostgreSQL database dump complete
--

