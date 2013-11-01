--
-- PostgreSQL database dump
--

\connect - alex

--
-- TOC entry 2 (OID 649554)
-- Name: legacy; Type: SCHEMA; Schema: -; Owner: alex
--

CREATE SCHEMA legacy;


--
-- TOC entry 3 (OID 649556)
-- Name: orchid; Type: SCHEMA; Schema: -; Owner: alex
--

CREATE SCHEMA orchid;


SET search_path = legacy, pg_catalog;

--
-- TOC entry 4 (OID 649559)
-- Name: log_tid; Type: SEQUENCE; Schema: legacy; Owner: alex
--

CREATE SEQUENCE log_tid
    START 1
    INCREMENT 1
    MAXVALUE 9223372036854775807
    MINVALUE 1
    CACHE 2048
    CYCLE;


--
-- TOC entry 5 (OID 649561)
-- Name: log; Type: TABLE; Schema: legacy; Owner: alex
--

CREATE TABLE log (
    who character varying(32) NOT NULL,
    quip character varying(384) NOT NULL,
    stamp abstime NOT NULL,
    channel character varying(25) NOT NULL,
    tid bigint DEFAULT nextval('legacy.log_tid'::text) NOT NULL
);


