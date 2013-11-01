-- pg_dump -i -s -h goro-i.putar botdb_elvis
--
-- PostgreSQL database dump
--

\connect - elvis

SET search_path = public, pg_catalog;

--
-- TOC entry 3 (OID 16998)
-- Name: config; Type: TABLE; Schema: public; Owner: elvis
--

CREATE TABLE config (
    "key" character varying(20) NOT NULL,
    value character varying(100)
);


--
-- TOC entry 4 (OID 16998)
-- Name: config; Type: ACL; Schema: public; Owner: elvis
--

REVOKE ALL ON TABLE config FROM PUBLIC;
GRANT SELECT ON TABLE config TO cormac;


--
-- TOC entry 5 (OID 17000)
-- Name: maintainers; Type: TABLE; Schema: public; Owner: elvis
--

CREATE TABLE maintainers (
    nick character varying(100) NOT NULL
);


--
-- TOC entry 6 (OID 17002)
-- Name: modules; Type: TABLE; Schema: public; Owner: elvis
--

-- "boolean" not valid in oracle??

CREATE TABLE modules (
    name character varying(20) NOT NULL,
    "default" boolean,
    code text
);


\connect - alex

SET search_path = public, pg_catalog;

--
-- TOC entry 7 (OID 17016)
-- Name: karma; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE karma (
    item text,
    value integer
);


--
-- TOC entry 8 (OID 17016)
-- Name: karma; Type: ACL; Schema: public; Owner: alex
--

REVOKE ALL ON TABLE karma FROM PUBLIC;
GRANT ALL ON TABLE karma TO cormac;


--
-- TOC entry 9 (OID 17029)
-- Name: log; Type: TABLE; Schema: public; Owner: alex
--

-- abstime not supported in oracle...?

CREATE TABLE log (
    who character varying(15),
    quip text,
    stamp abstime,
    channel character varying(25)
);


--
-- TOC entry 10 (OID 17029)
-- Name: log; Type: ACL; Schema: public; Owner: alex
--

REVOKE ALL ON TABLE log FROM PUBLIC;
GRANT ALL ON TABLE log TO cormac;


--
-- TOC entry 11 (OID 17036)
-- Name: profits; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE profits (
    who character varying(32) NOT NULL,
    profit double precision
);


--
-- TOC entry 12 (OID 17038)
-- Name: gobbles_advisories; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE gobbles_advisories (
    advisory_name character varying(32) NOT NULL,
    content text
);


--
-- TOC entry 13 (OID 17043)
-- Name: nv_storage; Type: TABLE; Schema: public; Owner: alex
--

-- bytea becomes "blob"

CREATE TABLE nv_storage (
    recordname character varying(256) NOT NULL,
    data bytea NOT NULL
);


--
-- TOC entry 14 (OID 17048)
-- Name: quotes; Type: TABLE; Schema: public; Owner: alex
--

-- boolean not available in oracle

CREATE TABLE quotes (
    whose text,
    quote text,
    personal boolean
);


--
-- TOC entry 15 (OID 923235)
-- Name: market_players; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE market_players (
    player character varying(32) NOT NULL
);


--
-- TOC entry 16 (OID 923266)
-- Name: stocks; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE stocks (
    player character varying(32),
    initial_price double precision,
    shares integer,
    stock character varying(8)
);


--
-- TOC entry 17 (OID 923478)
-- Name: channels; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE channels (
    channel character varying(64) NOT NULL
);


--
-- TOC entry 18 (OID 924456)
-- Name: infobot_backup; Type: TABLE; Schema: public; Owner: alex
--

-- this table needs to go away

CREATE TABLE infobot_backup (
    term text,
    definition text
) WITHOUT OIDS;


--
-- TOC entry 19 (OID 924499)
-- Name: infobot; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE infobot (
    term character varying(180) NOT NULL,
    definition character varying(180) NOT NULL
);


--
-- TOC entry 20 (OID 996089)
-- Name: infobot_dupes; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE infobot_dupes (
    term character varying(180)
);


--
-- TOC entry 21 (OID 1082154)
-- Name: translations; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE translations (
    trans_from text,
    fromlanguage character(16),
    tolanguage character(16),
    translation text
);


--
-- TOC entry 22 (OID 1082154)
-- Name: translations; Type: ACL; Schema: public; Owner: alex
--

REVOKE ALL ON TABLE translations FROM PUBLIC;


--
-- TOC entry 23 (OID 1157463)
-- Name: quiet; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE quiet (
    channel character varying(32) NOT NULL,
    count integer NOT NULL,
    whichday date NOT NULL
);


--
-- TOC entry 24 (OID 1599115)
-- Name: irc_joins; Type: TABLE; Schema: public; Owner: alex
--

CREATE TABLE irc_joins (
    who character varying(32) NOT NULL,
    channel character varying(32) NOT NULL,
    stamp timestamp without time zone NOT NULL
);


--
-- TOC entry 2 (OID 1600357)
-- Name: aop_id_seq; Type: SEQUENCE; Schema: public; Owner: alex
--

-- create sequence syntax is different in oracle than postgres

CREATE SEQUENCE aop_id_seq
    START 1
    INCREMENT 1
    MAXVALUE 9223372036854775807
    MINVALUE 1
    CACHE 1;


--
-- TOC entry 25 (OID 1600372)
-- Name: autoop; Type: TABLE; Schema: public; Owner: alex
--

-- this has been created without the aop_id field

CREATE TABLE autoop (
    who_added character varying(128) NOT NULL,
    line character varying(128) NOT NULL,
    channel character varying(32) NOT NULL,
    aop_id integer DEFAULT (nextval('aop_id_seq'::text))::integer NOT NULL
);


--
-- TOC entry 33 (OID 251431)
-- Name: karma_idx; Type: INDEX; Schema: public; Owner: alex
--

-- cant index fields with "datatype LOB" in oracle, e.g., text or "clob".

CREATE INDEX karma_idx ON karma USING btree (item, value);


--
-- TOC entry 30 (OID 251432)
-- Name: item_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX item_idx ON karma USING btree (item);


--
-- TOC entry 34 (OID 251433)
-- Name: value_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX value_idx ON karma USING btree (value);


--
-- TOC entry 31 (OID 251434)
-- Name: k_u_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE UNIQUE INDEX k_u_idx ON karma USING btree (item);


--
-- TOC entry 38 (OID 251439)
-- Name: log_who_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX log_who_idx ON log USING btree (who);


--
-- TOC entry 37 (OID 251440)
-- Name: log_stamp_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX log_stamp_idx ON log USING btree (stamp);


--
-- TOC entry 35 (OID 251441)
-- Name: log_channel_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX log_channel_idx ON log USING btree (channel);


--
-- TOC entry 36 (OID 251442)
-- Name: log_quip_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX log_quip_idx ON log USING btree (quip);


--
-- TOC entry 39 (OID 251443)
-- Name: log_who_upper_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX log_who_upper_idx ON log USING btree (upper(who));


--
-- TOC entry 32 (OID 251444)
-- Name: k_u_lower_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE UNIQUE INDEX k_u_lower_idx ON karma USING btree (lower(item));


--
-- TOC entry 44 (OID 923239)
-- Name: player_upper_distinct_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE UNIQUE INDEX player_upper_distinct_idx ON market_players USING btree (upper(player));


--
-- TOC entry 50 (OID 923530)
-- Name: upper_chan_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE UNIQUE INDEX upper_chan_idx ON channels USING btree (upper(channel));


--
-- TOC entry 45 (OID 946751)
-- Name: player_index; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX player_index ON stocks USING btree (player);


--
-- TOC entry 47 (OID 947165)
-- Name: stock_index; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX stock_index ON stocks USING btree (stock);


--
-- TOC entry 48 (OID 947631)
-- Name: stock_player_index; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX stock_player_index ON stocks USING btree (stock, player);


--
-- TOC entry 51 (OID 998789)
-- Name: ib_lookup_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE UNIQUE INDEX ib_lookup_idx ON infobot USING btree (term, definition);


\connect - elvis

SET search_path = public, pg_catalog;

--
-- TOC entry 26 (OID 1000287)
-- Name: config_kv_idx; Type: INDEX; Schema: public; Owner: elvis
--

CREATE INDEX config_kv_idx ON config USING btree ("key", value);


\connect - alex

SET search_path = public, pg_catalog;

--
-- TOC entry 52 (OID 1000868)
-- Name: ibt_upper_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX ibt_upper_idx ON infobot USING btree (upper(term));


--
-- TOC entry 46 (OID 1033978)
-- Name: sp_stock_unique_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE UNIQUE INDEX sp_stock_unique_idx ON stocks USING btree (stock, player);


--
-- TOC entry 58 (OID 1082159)
-- Name: translation_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE UNIQUE INDEX translation_idx ON translations USING btree (upper(translation));


--
-- TOC entry 56 (OID 1082160)
-- Name: lang_index; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX lang_index ON translations USING btree (fromlanguage, tolanguage);


--
-- TOC entry 57 (OID 1082161)
-- Name: trans_from_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE UNIQUE INDEX trans_from_idx ON translations USING btree (upper(trans_from));


--
-- TOC entry 60 (OID 1601511)
-- Name: line_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX line_idx ON autoop USING btree (line);


--
-- TOC entry 59 (OID 1601512)
-- Name: id_idx; Type: INDEX; Schema: public; Owner: alex
--

CREATE INDEX id_idx ON autoop USING btree (aop_id);


\connect - elvis

SET search_path = public, pg_catalog;

--
-- TOC entry 27 (OID 251445)
-- Name: config_pkey; Type: CONSTRAINT; Schema: public; Owner: elvis
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_pkey PRIMARY KEY ("key");


--
-- TOC entry 28 (OID 251447)
-- Name: maintainers_pkey; Type: CONSTRAINT; Schema: public; Owner: elvis
--

ALTER TABLE ONLY maintainers
    ADD CONSTRAINT maintainers_pkey PRIMARY KEY (nick);


--
-- TOC entry 29 (OID 251449)
-- Name: modules_pkey; Type: CONSTRAINT; Schema: public; Owner: elvis
--

ALTER TABLE ONLY modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (name);


\connect - alex

SET search_path = public, pg_catalog;

--
-- TOC entry 40 (OID 251453)
-- Name: profits_pkey; Type: CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY profits
    ADD CONSTRAINT profits_pkey PRIMARY KEY (who);


--
-- TOC entry 41 (OID 251455)
-- Name: gobbles_advisories_pkey; Type: CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY gobbles_advisories
    ADD CONSTRAINT gobbles_advisories_pkey PRIMARY KEY (advisory_name);


--
-- TOC entry 42 (OID 251457)
-- Name: nv_storage_pkey; Type: CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY nv_storage
    ADD CONSTRAINT nv_storage_pkey PRIMARY KEY (recordname);


--
-- TOC entry 43 (OID 923237)
-- Name: market_players_pkey; Type: CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY market_players
    ADD CONSTRAINT market_players_pkey PRIMARY KEY (player);


--
-- TOC entry 49 (OID 923480)
-- Name: channels_pkey; Type: CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (channel);


--
-- TOC entry 54 (OID 924501)
-- Name: infobot_pkey; Type: CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY infobot
    ADD CONSTRAINT infobot_pkey PRIMARY KEY (term);


--
-- TOC entry 53 (OID 924503)
-- Name: infobot_definition_key; Type: CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY infobot
    ADD CONSTRAINT infobot_definition_key UNIQUE (definition);


--
-- TOC entry 55 (OID 996091)
-- Name: infobot_dupes_term_key; Type: CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY infobot_dupes
    ADD CONSTRAINT infobot_dupes_term_key UNIQUE (term);


--
-- TOC entry 61 (OID 996093)
-- Name: $1; Type: CONSTRAINT; Schema: public; Owner: alex
--

ALTER TABLE ONLY infobot_dupes
    ADD CONSTRAINT "$1" FOREIGN KEY (term) REFERENCES infobot(term) ON UPDATE NO ACTION ON DELETE NO ACTION;


