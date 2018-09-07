--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.5
-- Dumped by pg_dump version 9.6.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = earmouth, pg_catalog;

--
-- Data for Name: users; Type: TABLE DATA; Schema: earmouth; Owner: d50b
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE users DISABLE TRIGGER ALL;

INSERT INTO users (id, person_id, apiuser, apipass, public_id, public_name, bio) VALUES (1, 1, 'OGhUkqpm', '5xLFkZrT', 'p9q', 'Derek Sivers', 'creator of EarMouth');
INSERT INTO users (id, person_id, apiuser, apipass, public_id, public_name, bio) VALUES (2, 8, 'iFtUxFn1', 'BHqDOp07', '8qa', 'Yoko', 'Sean’s mom');
INSERT INTO users (id, person_id, apiuser, apipass, public_id, public_name, bio) VALUES (3, 2, 'eHqR0bL1', 'BmOai5BG', 'vC2', 'Bill W', 'chocolate dude');

ALTER TABLE users ENABLE TRIGGER ALL;

--
-- Data for Name: calls; Type: TABLE DATA; Schema: earmouth; Owner: d50b
--

ALTER TABLE calls DISABLE TRIGGER ALL;

INSERT INTO calls (id, public_id, caller, callee, started_at, finished_at) VALUES (1, 'Ov8P', 1, 3, '2017-10-22 21:25:40+13', '2017-10-22 22:27:43+13');


ALTER TABLE calls ENABLE TRIGGER ALL;

--
-- Name: calls_id_seq; Type: SEQUENCE SET; Schema: earmouth; Owner: d50b
--

SELECT pg_catalog.setval('calls_id_seq', 1, true);


--
-- Data for Name: connections; Type: TABLE DATA; Schema: earmouth; Owner: d50b
--

ALTER TABLE connections DISABLE TRIGGER ALL;

INSERT INTO connections (id, user1, user2, created_at, revoked_at, revoked_by) VALUES (1, 1, 3, '2017-10-22', NULL, NULL);


ALTER TABLE connections ENABLE TRIGGER ALL;

--
-- Name: connections_id_seq; Type: SEQUENCE SET; Schema: earmouth; Owner: d50b
--

SELECT pg_catalog.setval('connections_id_seq', 1, true);



--
-- Data for Name: invitations; Type: TABLE DATA; Schema: earmouth; Owner: d50b
--

ALTER TABLE invitations DISABLE TRIGGER ALL;

INSERT INTO invitations (id, person_id, code, created_by, created_at, claimed_at) VALUES (1, 8, 'QOGUB8', 1, '2017-10-22', '2017-10-22');
INSERT INTO invitations (id, person_id, code, created_by, created_at, claimed_at) VALUES (2, 7, 'WC63KK', 1, '2017-10-22', NULL);
INSERT INTO invitations (id, person_id, code, created_by, created_at, claimed_at) VALUES (3, 2, 'BUU8D1', 1, '2017-10-22', '2017-10-22');
INSERT INTO invitations (id, person_id, code, created_by, created_at, claimed_at) VALUES (4, 4, 'ABC123', 1, '2017-12-15', NULL);


ALTER TABLE invitations ENABLE TRIGGER ALL;

--
-- Name: invitations_id_seq; Type: SEQUENCE SET; Schema: earmouth; Owner: d50b
--

SELECT pg_catalog.setval('invitations_id_seq', 4, true);


--
-- Data for Name: requests; Type: TABLE DATA; Schema: earmouth; Owner: d50b
--

ALTER TABLE requests DISABLE TRIGGER ALL;

INSERT INTO requests (id, requester, requestee, created_at, approved, closed_at) VALUES (1, 3, 2, '2017-10-22', NULL, NULL);


ALTER TABLE requests ENABLE TRIGGER ALL;

--
-- Name: requests_id_seq; Type: SEQUENCE SET; Schema: earmouth; Owner: d50b
--

SELECT pg_catalog.setval('requests_id_seq', 1, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: earmouth; Owner: d50b
--

SELECT pg_catalog.setval('users_id_seq', 3, true);



--
-- PostgreSQL database dump complete
--

