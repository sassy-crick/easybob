--
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 15.6 (Debian 15.6-0+deb12u1)
-- Dumped by pg_dump version 15.6 (Debian 15.6-0+deb12u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE easybob;
--
-- Name: easybob; Type: DATABASE; Schema: -; Owner: USER
--

CREATE DATABASE easybob WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_GB.UTF-8';


ALTER DATABASE easybob OWNER TO USER;

\connect easybob

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ec_name; Type: TABLE; Schema: public; Owner: USER
--

CREATE TABLE public.ec_name (
    ec_id integer NOT NULL,
    ec_name character varying(500),
    sw_name_id integer,
    sw_version_id integer,
    toolchain_id integer,
    toolchain_version_id integer,
    module_id integer,
    is_installed character varying(10)
);


ALTER TABLE public.ec_name OWNER TO USER;

--
-- Name: ec_name_ec_id_seq; Type: SEQUENCE; Schema: public; Owner: USER
--

CREATE SEQUENCE public.ec_name_ec_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ec_name_ec_id_seq OWNER TO USER;

--
-- Name: ec_name_ec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: USER
--

ALTER SEQUENCE public.ec_name_ec_id_seq OWNED BY public.ec_name.ec_id;


--
-- Name: module; Type: TABLE; Schema: public; Owner: USER
--

CREATE TABLE public.module (
    id integer NOT NULL,
    module character(20)
);


ALTER TABLE public.module OWNER TO USER;

--
-- Name: module_id_seq; Type: SEQUENCE; Schema: public; Owner: USER
--

CREATE SEQUENCE public.module_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.module_id_seq OWNER TO USER;

--
-- Name: module_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: USER
--

ALTER SEQUENCE public.module_id_seq OWNED BY public.module.id;


--
-- Name: sw_name; Type: TABLE; Schema: public; Owner: USER
--

CREATE TABLE public.sw_name (
    id integer NOT NULL,
    sw_name character varying(50),
    sw_description character varying(500),
    sw_cite character varying(500),
    sw_module integer
);


ALTER TABLE public.sw_name OWNER TO USER;

--
-- Name: sw_name_id_seq; Type: SEQUENCE; Schema: public; Owner: USER
--

CREATE SEQUENCE public.sw_name_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sw_name_id_seq OWNER TO USER;

--
-- Name: sw_name_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: USER
--

ALTER SEQUENCE public.sw_name_id_seq OWNED BY public.sw_name.id;


--
-- Name: sw_version; Type: TABLE; Schema: public; Owner: USER
--

CREATE TABLE public.sw_version (
    id integer NOT NULL,
    sw_version character varying(50)
);


ALTER TABLE public.sw_version OWNER TO USER;

--
-- Name: sw_version_id_seq; Type: SEQUENCE; Schema: public; Owner: USER
--

CREATE SEQUENCE public.sw_version_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sw_version_id_seq OWNER TO USER;

--
-- Name: sw_version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: USER
--

ALTER SEQUENCE public.sw_version_id_seq OWNED BY public.sw_version.id;


--
-- Name: testing; Type: TABLE; Schema: public; Owner: USER
--

CREATE TABLE public.testing (
    ec_id integer NOT NULL,
    ec_name character varying(500),
    sw_name_id integer,
    sw_version_id integer
);


ALTER TABLE public.testing OWNER TO USER;

--
-- Name: testing_ec_id_seq; Type: SEQUENCE; Schema: public; Owner: USER
--

CREATE SEQUENCE public.testing_ec_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.testing_ec_id_seq OWNER TO USER;

--
-- Name: testing_ec_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: USER
--

ALTER SEQUENCE public.testing_ec_id_seq OWNED BY public.testing.ec_id;


--
-- Name: toolchain; Type: TABLE; Schema: public; Owner: USER
--

CREATE TABLE public.toolchain (
    id integer NOT NULL,
    toolchain character varying(50)
);


ALTER TABLE public.toolchain OWNER TO USER;

--
-- Name: toolchain_id_seq; Type: SEQUENCE; Schema: public; Owner: USER
--

CREATE SEQUENCE public.toolchain_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.toolchain_id_seq OWNER TO USER;

--
-- Name: toolchain_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: USER
--

ALTER SEQUENCE public.toolchain_id_seq OWNED BY public.toolchain.id;


--
-- Name: toolchain_version; Type: TABLE; Schema: public; Owner: USER
--

CREATE TABLE public.toolchain_version (
    id integer NOT NULL,
    toolchain_version character varying(50)
);


ALTER TABLE public.toolchain_version OWNER TO USER;

--
-- Name: toolchain_version_id_seq; Type: SEQUENCE; Schema: public; Owner: USER
--

CREATE SEQUENCE public.toolchain_version_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.toolchain_version_id_seq OWNER TO USER;

--
-- Name: toolchain_version_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: USER
--

ALTER SEQUENCE public.toolchain_version_id_seq OWNED BY public.toolchain_version.id;


--
-- Name: ec_name ec_id; Type: DEFAULT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.ec_name ALTER COLUMN ec_id SET DEFAULT nextval('public.ec_name_ec_id_seq'::regclass);


--
-- Name: module id; Type: DEFAULT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.module ALTER COLUMN id SET DEFAULT nextval('public.module_id_seq'::regclass);


--
-- Name: sw_name id; Type: DEFAULT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.sw_name ALTER COLUMN id SET DEFAULT nextval('public.sw_name_id_seq'::regclass);


--
-- Name: sw_version id; Type: DEFAULT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.sw_version ALTER COLUMN id SET DEFAULT nextval('public.sw_version_id_seq'::regclass);


--
-- Name: testing ec_id; Type: DEFAULT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.testing ALTER COLUMN ec_id SET DEFAULT nextval('public.testing_ec_id_seq'::regclass);


--
-- Name: toolchain id; Type: DEFAULT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.toolchain ALTER COLUMN id SET DEFAULT nextval('public.toolchain_id_seq'::regclass);


--
-- Name: toolchain_version id; Type: DEFAULT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.toolchain_version ALTER COLUMN id SET DEFAULT nextval('public.toolchain_version_id_seq'::regclass);


--
-- Data for Name: ec_name; Type: TABLE DATA; Schema: public; Owner: USER
--

COPY public.ec_name (ec_id, ec_name, sw_name_id, sw_version_id, toolchain_id, toolchain_version_id, module_id, is_installed) FROM stdin;
\.
COPY public.ec_name (ec_id, ec_name, sw_name_id, sw_version_id, toolchain_id, toolchain_version_id, module_id, is_installed) FROM '$$PATH$$/3412.dat';

--
-- Data for Name: module; Type: TABLE DATA; Schema: public; Owner: USER
--

COPY public.module (id, module) FROM stdin;
\.
COPY public.module (id, module) FROM '$$PATH$$/3408.dat';

--
-- Data for Name: sw_name; Type: TABLE DATA; Schema: public; Owner: USER
--

COPY public.sw_name (id, sw_name, sw_description, sw_cite, sw_module) FROM stdin;
\.
COPY public.sw_name (id, sw_name, sw_description, sw_cite, sw_module) FROM '$$PATH$$/3402.dat';

--
-- Data for Name: sw_version; Type: TABLE DATA; Schema: public; Owner: USER
--

COPY public.sw_version (id, sw_version) FROM stdin;
\.
COPY public.sw_version (id, sw_version) FROM '$$PATH$$/3406.dat';

--
-- Data for Name: testing; Type: TABLE DATA; Schema: public; Owner: USER
--

COPY public.testing (ec_id, ec_name, sw_name_id, sw_version_id) FROM stdin;
\.
COPY public.testing (ec_id, ec_name, sw_name_id, sw_version_id) FROM '$$PATH$$/3410.dat';

--
-- Data for Name: toolchain; Type: TABLE DATA; Schema: public; Owner: USER
--

COPY public.toolchain (id, toolchain) FROM stdin;
\.
COPY public.toolchain (id, toolchain) FROM '$$PATH$$/3400.dat';

--
-- Data for Name: toolchain_version; Type: TABLE DATA; Schema: public; Owner: USER
--

COPY public.toolchain_version (id, toolchain_version) FROM stdin;
\.
COPY public.toolchain_version (id, toolchain_version) FROM '$$PATH$$/3404.dat';

--
-- Name: ec_name_ec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: USER
--

SELECT pg_catalog.setval('public.ec_name_ec_id_seq', 2, true);


--
-- Name: module_id_seq; Type: SEQUENCE SET; Schema: public; Owner: USER
--

SELECT pg_catalog.setval('public.module_id_seq', 24, true);


--
-- Name: sw_name_id_seq; Type: SEQUENCE SET; Schema: public; Owner: USER
--

SELECT pg_catalog.setval('public.sw_name_id_seq', 1, true);


--
-- Name: sw_version_id_seq; Type: SEQUENCE SET; Schema: public; Owner: USER
--

SELECT pg_catalog.setval('public.sw_version_id_seq', 1, true);


--
-- Name: testing_ec_id_seq; Type: SEQUENCE SET; Schema: public; Owner: USER
--

SELECT pg_catalog.setval('public.testing_ec_id_seq', 95, true);


--
-- Name: toolchain_id_seq; Type: SEQUENCE SET; Schema: public; Owner: USER
--

SELECT pg_catalog.setval('public.toolchain_id_seq', 7, true);


--
-- Name: toolchain_version_id_seq; Type: SEQUENCE SET; Schema: public; Owner: USER
--

SELECT pg_catalog.setval('public.toolchain_version_id_seq', 8, true);


--
-- Name: ec_name ec_name_pkey; Type: CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.ec_name
    ADD CONSTRAINT ec_name_pkey PRIMARY KEY (ec_id);


--
-- Name: module module_pkey; Type: CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.module
    ADD CONSTRAINT module_pkey PRIMARY KEY (id);


--
-- Name: sw_name sw_name_pkey; Type: CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.sw_name
    ADD CONSTRAINT sw_name_pkey PRIMARY KEY (id);


--
-- Name: sw_version sw_version_pkey; Type: CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.sw_version
    ADD CONSTRAINT sw_version_pkey PRIMARY KEY (id);


--
-- Name: testing testing_pkey; Type: CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.testing
    ADD CONSTRAINT testing_pkey PRIMARY KEY (ec_id);


--
-- Name: toolchain toolchain_pkey; Type: CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.toolchain
    ADD CONSTRAINT toolchain_pkey PRIMARY KEY (id);


--
-- Name: toolchain_version toolchain_version_pkey; Type: CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.toolchain_version
    ADD CONSTRAINT toolchain_version_pkey PRIMARY KEY (id);


--
-- Name: ec_name fk_module_id; Type: FK CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.ec_name
    ADD CONSTRAINT fk_module_id FOREIGN KEY (module_id) REFERENCES public.module(id);


--
-- Name: testing fk_sw_name_id; Type: FK CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.testing
    ADD CONSTRAINT fk_sw_name_id FOREIGN KEY (sw_name_id) REFERENCES public.sw_name(id);


--
-- Name: ec_name fk_sw_name_id; Type: FK CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.ec_name
    ADD CONSTRAINT fk_sw_name_id FOREIGN KEY (sw_name_id) REFERENCES public.sw_name(id);


--
-- Name: testing fk_sw_version; Type: FK CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.testing
    ADD CONSTRAINT fk_sw_version FOREIGN KEY (sw_version_id) REFERENCES public.sw_version(id);


--
-- Name: ec_name fk_sw_version_id; Type: FK CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.ec_name
    ADD CONSTRAINT fk_sw_version_id FOREIGN KEY (sw_version_id) REFERENCES public.sw_version(id);


--
-- Name: ec_name fk_toolchein_id; Type: FK CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.ec_name
    ADD CONSTRAINT fk_toolchein_id FOREIGN KEY (toolchain_id) REFERENCES public.toolchain(id);


--
-- Name: ec_name fk_toolchein_version_id; Type: FK CONSTRAINT; Schema: public; Owner: USER
--

ALTER TABLE ONLY public.ec_name
    ADD CONSTRAINT fk_toolchein_version_id FOREIGN KEY (toolchain_version_id) REFERENCES public.toolchain_version(id);


--
-- PostgreSQL database dump complete
--

