--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = now, pg_catalog;

--
-- Data for Name: urls; Type: TABLE DATA; Schema: now; Owner: d50b
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE urls DISABLE TRIGGER ALL;

INSERT INTO urls (id, person_id, created_at, updated_at, short, long) VALUES (1, 1, '2015-11-10', '2015-11-10', 'sivers.org/now', 'http://sivers.org/now');
INSERT INTO urls (id, person_id, created_at, updated_at, short, long) VALUES (2, 2, '2015-11-10', '2015-11-10', 'wonka.com/now', 'http://www.wonka.com/now/');
INSERT INTO urls (id, person_id, created_at, updated_at, short, long) VALUES (3, NULL, '2015-11-10', '2015-11-10', 'salt.com/now', 'http://salt.com/now/');
INSERT INTO urls (id, person_id, created_at, updated_at, short, long) VALUES (4, NULL, '2015-11-10', '2015-11-10', 'oompa.net/now.html', 'http://oompa.net/now.html');
INSERT INTO urls (id, person_id, created_at, updated_at, short, long) VALUES (5, NULL, '2015-11-10', '2015-11-10', 'gongli.cn/now', NULL);


ALTER TABLE urls ENABLE TRIGGER ALL;

--
-- Name: urls_id_seq; Type: SEQUENCE SET; Schema: now; Owner: d50b
--

SELECT pg_catalog.setval('urls_id_seq', 5, true);


--
-- PostgreSQL database dump complete
--

