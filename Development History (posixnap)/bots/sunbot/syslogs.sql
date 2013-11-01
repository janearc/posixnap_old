--
-- PostgreSQL database dump
--

\connect - tyler

SET search_path = public, pg_catalog;

--
-- TOC entry 2 (OID 199545)
-- Name: hosts; Type: TABLE; Schema: public; Owner: tyler
--

CREATE TABLE hosts (
    hostname character varying(25) NOT NULL,
    ip inet
);


--
-- TOC entry 3 (OID 199561)
-- Name: current_logs; Type: TABLE; Schema: public; Owner: tyler
--

CREATE TABLE current_logs (
    stamp timestamp without time zone DEFAULT now(),
    hostname character varying(25),
    ip inet,
    log text
);


--
-- TOC entry 5 (OID 199592)
-- Name: curr_logs_cgi_idx; Type: INDEX; Schema: public; Owner: tyler
--

CREATE INDEX curr_logs_cgi_idx ON current_logs USING btree (stamp, hostname, ip, log);


--
-- TOC entry 4 (OID 199550)
-- Name: hosts_pkey; Type: CONSTRAINT; Schema: public; Owner: tyler
--

ALTER TABLE ONLY hosts
    ADD CONSTRAINT hosts_pkey PRIMARY KEY (hostname);


--
-- TOC entry 6 (OID 199567)
-- Name: $1; Type: CONSTRAINT; Schema: public; Owner: tyler
--

ALTER TABLE ONLY current_logs
    ADD CONSTRAINT "$1" FOREIGN KEY (hostname) REFERENCES hosts(hostname) ON UPDATE NO ACTION ON DELETE NO ACTION;


