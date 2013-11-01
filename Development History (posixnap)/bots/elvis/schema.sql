-- /* psql -U magnus -h10.2 template1 -f schema.sql */

-- /* config
-- username, password, server, port, channel, maintainer

-- subs
-- name, readonly, code
-- */
\connect template1 postgres
DROP DATABASE botdb_elvis;
CREATE DATABASE botdb_elvis;
\connect botdb_elvis elvis

CREATE TABLE "config" (
        "key" character varying(20) NOT NULL,
        "value" character varying(100),
        PRIMARY KEY ("key")
);


CREATE TABLE "maintainers" (
        "nick" character varying(100) NOT NULL,
        PRIMARY KEY ("nick")
);

CREATE TABLE "modules" (
	"name" character varying(20) NOT NULL,
	"default" bool,
	"code" text,
	PRIMARY KEY ("name")
);

CREATE TABLE "elvisquotes" (
	"id" serial, 
	"quote" text,
	"last" timestamp DEFAULT NOW(),
	PRIMARY KEY ("id")
);
