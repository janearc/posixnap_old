--
-- PostgreSQL database dump
--

--
-- TOC entry 3 (OID 1226906)
-- Name: legacy; Type: SCHEMA; Schema: -; Owner: 
--
--
-- TOC entry 4 (OID 1226907)
-- Name: aol; Type: SCHEMA; Schema: -; Owner: 
--
SET SESSION AUTHORIZATION 'postgres';

--
-- TOC entry 6 (OID 2200)
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


SET SESSION AUTHORIZATION 'alex';

SET search_path = public, pg_catalog;

--
-- TOC entry 7 (OID 1246004)
-- Name: msgids; Type: SEQUENCE; Schema: public; Owner: alex
--

CREATE SEQUENCE msgids
    START WITH 1
    INCREMENT BY 1
    MAXVALUE 2147483647
    NO MINVALUE
    CACHE 1;


--
-- TOC entry 8 (OID 1246006)
-- Name: list_definitions; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE list_definitions (
    list_destination character varying(256) NOT NULL,
    listname text
);


--
-- TOC entry 10 (OID 1246011)
-- Name: messages; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE messages (
    msgid integer DEFAULT nextval('msgids'::text) primary key,
    sender character varying(256),
    recip character varying(256),
    date timestamp without time zone DEFAULT now(),
    list_destination character varying,
    body text
);


--
-- TOC entry 12 (OID 1246018)
-- Name: list_patterns; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE list_patterns (
    list_destination character varying(256) NOT NULL,
    expression character varying(32) NOT NULL
);


--
-- TOC entry 14 (OID 1246020)
-- Name: list_folders; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE list_folders (
    list_destination character varying(256) NOT NULL,
    list_folder character varying(256)
);


--
-- TOC entry 16 (OID 1246022)
-- Name: list_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY list_definitions
    ADD CONSTRAINT list_definitions_pkey PRIMARY KEY (list_destination);


--
-- TOC entry 17 (OID 1246024)
-- Name: list_folders_pkey; Type: CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY list_folders
    ADD CONSTRAINT list_folders_pkey PRIMARY KEY (list_destination);


--
-- TOC entry 18 (OID 1246026)
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY messages
    ADD CONSTRAINT "$1" FOREIGN KEY (list_destination) REFERENCES list_definitions(list_destination);


--
-- TOC entry 19 (OID 1246030)
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY list_patterns
    ADD CONSTRAINT "$1" FOREIGN KEY (list_destination) REFERENCES list_definitions(list_destination);


--
-- TOC entry 20 (OID 1246034)
-- Name: $1; Type: FK CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY list_folders
    ADD CONSTRAINT "$1" FOREIGN KEY (list_destination) REFERENCES list_definitions(list_destination);


SET SESSION AUTHORIZATION 'postgres';

--
-- TOC entry 5 (OID 2200)
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'Standard public schema';


SET SESSION AUTHORIZATION DEFAULT;

--
-- TOC entry 2 (OID 1246003)
-- Name: DATABASE email; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON DATABASE email IS '$Id: email.sql,v 1.4 2004-02-27 01:39:03 alex Exp $';


SET SESSION AUTHORIZATION 'alex';

--
-- TOC entry 9 (OID 1246006)
-- Name: TABLE list_definitions; Type: COMMENT; Schema: public; Owner: alex
--

COMMENT ON TABLE list_definitions IS 'Used to record the address of the list, as well as what its official name is.';


--
-- TOC entry 11 (OID 1246011)
-- Name: TABLE messages; Type: COMMENT; Schema: public; Owner: alex
--

COMMENT ON TABLE messages IS 'Storage of actual email messages.';


--
-- TOC entry 13 (OID 1246018)
-- Name: TABLE list_patterns; Type: COMMENT; Schema: public; Owner: alex
--

COMMENT ON TABLE list_patterns IS 'A sequence of expressions when, evaluated by perl, will return the identity of the list for collating.';


--
-- TOC entry 15 (OID 1246020)
-- Name: TABLE list_folders; Type: COMMENT; Schema: public; Owner: alex
--

COMMENT ON TABLE list_folders IS 'The preferred destinations of list-bound email.';


