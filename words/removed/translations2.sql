--
-- PostgreSQL database dump
--

-- Dumped from database version 10.3
-- Dumped by pg_dump version 10.3

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
-- Data for Name: translations; Type: TABLE DATA; Schema: words; Owner: d50b
--

INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (4, 'aaaaaaaa', 'zh', '这里头条');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (8, 'aaaaaaab', 'zh', '一些大<胆的话>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (12, 'aaaaaaac', 'zh', '在<联和<斜体>字>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (16, 'aaaaaaad', 'zh', '<到><这个>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (1, 'aaaaaaaa', 'es', 'título aquí');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (3, 'aaaaaaaa', 'pt', 'headline aqui');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (5, 'aaaaaaab', 'es', 'algunas <palabras en negrita>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (7, 'aaaaaaab', 'pt', 'algumas <palavras em negrito>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (9, 'aaaaaaac', 'es', 'ahora <ligado y las <palabras en cursiva>>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (11, 'aaaaaaac', 'pt', 'agora <ligados e as palavras em <itálico>>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (13, 'aaaaaaad', 'es', 'conocer <de> <este>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (17, 'bbbbbbbb', 'es', 'hola');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (19, 'bbbbbbbb', 'pt', 'olá');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (20, 'bbbbbbbb', 'zh', '你好');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (21, 'bbbbbbbc', 'zh', '还没做完');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (22, 'bbbbbbbc', 'es', NULL);
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (23, 'bbbbbbbc', 'fr', NULL);
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (24, 'bbbbbbbc', 'pt', NULL);
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (15, 'aaaaaaad', 'pt', 'ver <sobre> <este>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (2, 'aaaaaaaa', 'fr', 'titre ici');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (6, 'aaaaaaab', 'fr', 'quelques <mots en gras>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (10, 'aaaaaaac', 'fr', 'maintenant <liés et mots <italiques>>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (14, 'aaaaaaad', 'fr', 'voir <à ce> <sujet>');
INSERT INTO words.translations (id, sentence_code, lang, translation) VALUES (18, 'bbbbbbbb', 'fr', 'bonjour');


--
-- Name: translations_id_seq; Type: SEQUENCE SET; Schema: words; Owner: d50b
--

SELECT pg_catalog.setval('words.translations_id_seq', 24, true);


--
-- PostgreSQL database dump complete
--

