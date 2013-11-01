--
-- Selected TOC Entries:
--
\connect - alex
--
-- TOC Entry ID 2 (OID 816659)
--
-- Name: taskids Type: SEQUENCE Owner: alex
--

CREATE SEQUENCE "taskids" start 1 increment 1 maxvalue 65535 minvalue 1  cache 128 cycle;

--
-- TOC Entry ID 4 (OID 816722)
--
-- Name: beeids Type: SEQUENCE Owner: alex
--

CREATE SEQUENCE "beeids" start 1 increment 1 maxvalue 65535 minvalue 1  cache 128 cycle;

--
-- TOC Entry ID 6 (OID 816753)
--
-- Name: workerbees Type: TABLE Owner: alex
--

CREATE TABLE "workerbees" (
	"bee" character varying(64) NOT NULL,
	"beeid" smallint DEFAULT nextval('beeids'::text) NOT NULL,
	Constraint "workerbees_pkey" Primary Key ("beeid")
);

--
-- TOC Entry ID 7 (OID 816768)
--
-- Name: tasks Type: TABLE Owner: alex
--

CREATE TABLE "tasks" (
	"client" character varying(32) DEFAULT 'BAE Systems' NOT NULL,
	"bee" character varying(32) NOT NULL,
	"taskid" integer DEFAULT nextval('taskids'::text),
	"contact_email" character varying(256) DEFAULT 'christopher.pryor@baesystems.com' NOT NULL,
	"taskname" character varying(64) DEFAULT 'Bzz Bzz Bzz!' NOT NULL
);

--
-- Data for TOC Entry ID 8 (OID 816753)
--
-- Name: workerbees Type: TABLE DATA Owner: alex
--


COPY "workerbees"  FROM stdin;
\.
--
-- Data for TOC Entry ID 9 (OID 816768)
--
-- Name: tasks Type: TABLE DATA Owner: alex
--


COPY "tasks"  FROM stdin;
\.
--
-- TOC Entry ID 12 (OID 816787)
--
-- Name: "RI_ConstraintTrigger_816786" Type: TRIGGER Owner: alex
--

CREATE CONSTRAINT TRIGGER "<unnamed>" AFTER INSERT OR UPDATE ON "tasks"  FROM "workerbees" NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_check_ins" ('<unnamed>', 'tasks', 'workerbees', 'UNSPECIFIED', 'bee', 'beeid');

--
-- TOC Entry ID 10 (OID 816789)
--
-- Name: "RI_ConstraintTrigger_816788" Type: TRIGGER Owner: alex
--

CREATE CONSTRAINT TRIGGER "<unnamed>" AFTER DELETE ON "workerbees"  FROM "tasks" NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_del" ('<unnamed>', 'tasks', 'workerbees', 'UNSPECIFIED', 'bee', 'beeid');

--
-- TOC Entry ID 11 (OID 816791)
--
-- Name: "RI_ConstraintTrigger_816790" Type: TRIGGER Owner: alex
--

CREATE CONSTRAINT TRIGGER "<unnamed>" AFTER UPDATE ON "workerbees"  FROM "tasks" NOT DEFERRABLE INITIALLY IMMEDIATE FOR EACH ROW EXECUTE PROCEDURE "RI_FKey_noaction_upd" ('<unnamed>', 'tasks', 'workerbees', 'UNSPECIFIED', 'bee', 'beeid');

--
-- TOC Entry ID 3 (OID 816659)
--
-- Name: taskids Type: SEQUENCE SET Owner: 
--

SELECT setval ('"taskids"', 1, 'f');

--
-- TOC Entry ID 5 (OID 816722)
--
-- Name: beeids Type: SEQUENCE SET Owner: 
--

SELECT setval ('"beeids"', 1, 'f');

