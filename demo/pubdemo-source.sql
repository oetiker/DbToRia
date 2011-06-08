-- #########################################################################
-- # SQL source for the PTP demo database ...
-- #########################################################################

-- #########################################################################
-- $Id: pubdemo-source.sql 4206 2011-04-05 14:24:29Z oetiker $
-- Change Log
-- $Log: $

-- #########################################################################
-- Setup the database
-- ##########################################################################
CREATE GROUP pubdemo_user;
CREATE GROUP pubdemo_admin;
CREATE GROUP pubdemo_reader;

CREATE USER pubdemo        IN GROUP pubdemo_admin,pubdemo_user PASSWORD 'pubdemo';
CREATE USER ptptest        IN GROUP pubdemo_user PASSWORD 'pubtest';
CREATE USER pubdemo_master IN GROUP pubdemo_admin,pubdemo_user;
CREATE USER pubdemo_read   IN GROUP pubdemo_reader;

DROP DATABASE pubdemo;
CREATE DATABASE pubdemo 
       WITH OWNER = pubdemo 
       TEMPLATE = template0 
       ENCODING = 'UTF8';
GRANT ALL ON DATABASE pubdemo TO pubdemo;

\connect pubdemo
COMMENT ON DATABASE pubdemo IS 'pubdemo';

-- our add the language

-- CREATE FUNCTION plpgsql_call_handler() returns language_handler
--         as '$libdir/plpgsql.so' LANGUAGE 'C';

CREATE TRUSTED PROCEDURAL LANGUAGE 'plpgsql'
       HANDLER plpgsql_call_handler150
       lancompiler 'PL/pgSQL';

SET search_path = public, pg_catalog;


-- #########################################################################
-- Lock everything UP
-- ##########################################################################
GRANT  ALL   ON SCHEMA public  TO   pubdemo;
GRANT  USAGE ON SCHEMA public  TO   GROUP pubdemo_user;
GRANT  USAGE ON SCHEMA public  TO   GROUP pubdemo_admin;
GRANT  USAGE ON SCHEMA public  TO   GROUP pubdemo_reader;

REVOKE ALL   ON DATABASE pubdemo FROM PUBLIC;
REVOKE ALL   ON SCHEMA   public  FROM PUBLIC;

-- let's loose our superior powers
SET SESSION AUTHORIZATION 'pubdemo';

-- ###########################################################################


-- get list of our tables --> select * from pg_tables where tableowner='pubdemo';

-- SET DateStyle TO 'European';

-- ######################
-- Field Meta Information
-- ######################

-- this table lists all fields which have special properties
CREATE TABLE meta_fields (
   meta_fields_table       NAME    NOT NULL,   -- Table Name
   meta_fields_field       NAME    NOT NULL,   -- Field Name
   meta_fields_attribute   TEXT    NOT NULL,   -- Attribute
   meta_fields_value       TEXT,   		-- Value
   UNIQUE(meta_fields_table,meta_fields_field,meta_fields_attribute)
);

GRANT SELECT ON meta_fields TO GROUP pubdemo_user;

-- ######################
-- Table Meta Information
-- ######################

CREATE TABLE meta_tables (
   -- Table Name
   meta_tables_table       NAME NOT NULL,
   -- Attribute
   meta_tables_attribute   TEXT NOT NULL,
   -- Value
   meta_tables_value       TEXT,
   UNIQUE(meta_tables_table,meta_tables_attribute)
);

GRANT SELECT ON meta_tables TO GROUP pubdemo_user;


-- raise an exception 

CREATE OR REPLACE FUNCTION elog(text) RETURNS BOOLEAN AS 
      $$ BEGIN RAISE EXCEPTION '%', $1 ; END; $$ LANGUAGE 'plpgsql';

CREATE table elog ( elog bool );
insert into elog values (true);

INSERT INTO meta_tables VALUES ('elog', 'hide','1');

CREATE OR REPLACE FUNCTION ingroup(name) RETURNS BOOLEAN AS $$
SELECT CASE WHEN (SELECT TRUE 
  FROM pg_user, pg_group
 WHERE groname = $1
   AND usename = CURRENT_USER
   AND usesysid = ANY (grolist)) THEN TRUE 
 ELSE FALSE
 END; $$
LANGUAGE SQL STABLE;


CREATE OR REPLACE FUNCTION nicetrim (text, int4) RETURNS text AS $$
        DECLARE
                str ALIAS FOR $1;
                len ALIAS FOR $2;
        BEGIN
                IF char_length(str) > len THEN
                        RETURN substring(str from 1 for len) || ' [...]';
                END IF;
                RETURN str;
        END; $$
LANGUAGE 'plpgsql' STABLE;

-- CREATE AGGREGATE array_accum (anyelement)
-- (
--     sfunc = array_append,
--     stype = anyarray,
--     initcond = '{}'
-- );

-- -- ## access 2010 insists on calling this function eventhough it does not exist
-- -- ## in postgresql ... so here it is and access 2010 is happy ...
-- CREATE OR REPLACE FUNCTION ident_current(name) RETURNS BIGINT AS $$
--    SELECT currval(regexp_replace($1,'.+public[."]+([^"]+)"?',E'\\1_\\1_id_seq')); 
-- $$ LANGUAGE SQL;
 

-- ############
-- store config information for ptp
-- ############

-- CREATE TABLE ptp_config (
--    ptp_config_id    SERIAL NOT NULL PRIMARY KEY,
--    ptp_config_hid   NAME    NOT NULL UNIQUE,
--    ptp_config_value TEXT   NOT NULL,
--    ptp_config_note  TEXT 
-- ) WITH OIDS;


-- grant insert,update,select on ptp_config to group pubdemo_admin;
-- grant select,update on ptp_config to group pubdemo_user;

-- COMMENT ON TABLE ptp_config IS 'Z PTP Config Table';
-- COMMENT ON COLUMN ptp_config.ptp_config_id IS 'ID';
-- COMMENT ON COLUMN ptp_config.ptp_config_hid IS 'Key';
-- COMMENT ON COLUMN ptp_config.ptp_config_value IS 'Value';
-- COMMENT ON COLUMN ptp_config.ptp_config_note IS 'Note';
-- INSERT INTO meta_fields VALUES ('ptp_config','ptp_config_note', 'widget','area');


-- CREATE OR REPLACE FUNCTION get_ptp_config(NAME) RETURNS TEXT AS $$
-- select ptp_config_value
-- from ptp_config 
-- where ptp_config_hid = $1;
-- $$ LANGUAGE 'sql' IMMUTABLE;

-- ############
-- Gender Types
-- ############

CREATE TABLE gender (
   gender_id     SERIAL NOT NULL PRIMARY KEY,            -- Unique ID
   gender_hid    VARCHAR(5) NOT NULL UNIQUE,             -- Human Readable ID
   gender_name   TEXT NOT NULL CHECK (gender_name != '') -- Full Name of Gender
) WITH OIDS;

GRANT SELECT ON gender TO GROUP pubdemo_user;
GRANT SELECT,UPDATE ON gender_gender_id_seq TO GROUP pubdemo_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON gender TO GROUP pubdemo_admin;

COMMENT ON TABLE gender IS 'Z Genders';
COMMENT ON COLUMN gender.gender_id IS 'ID';
COMMENT ON COLUMN gender.gender_hid IS 'Gender';
COMMENT ON COLUMN gender.gender_name IS 'Full Name';

CREATE OR REPLACE VIEW gender_combo AS
       SELECT gender_id AS id, gender_hid || ' -- ' || gender_name AS text FROM gender ORDER by gender_hid,gender_name;

GRANT SELECT ON gender_combo TO GROUP pubdemo_user;

-- ##############################################################################
-- Personnel table. Every worker is listed in this table
-- ##############################################################################

CREATE TABLE pers (
   pers_id     SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
   pers_hid    NAME NOT NULL UNIQUE,                    -- Human Readable Unique ID
   pers_first  TEXT NOT NULL CHECK (pers_first != ''),  -- First Name of Person
   pers_last   TEXT NOT NULL CHECK (pers_last != ''),   -- Last Name of Person
--   pers_sign   VARCHAR(2),               				-- Ihr Zeichen
--   pers_office_phone TEXT CHECK (pers_office_phone != ''), -- Office Phone Number
--   pers_office_room  TEXT CHECK (pers_office_room  != ''), -- Office Room Number
--   pers_home_phone TEXT CHECK (pers_home_phone != ''),  -- Home Phone Number
--  pers_mobile_phone TEXT CHECK (pers_mobile_phone != ''),  -- Mobile Number
   pers_desc   TEXT CHECK (pers_desc != '')             -- Explanation
--   pers_start   DATE   NOT NULL DEFAULT CURRENT_DATE,       -- Is the person active'
--   pers_end     DATE   CHECK ( pers_end is NULL or pers_end > pers_start )

) WITH OIDS;

GRANT SELECT,UPDATE ON pers_pers_id_seq TO GROUP pubdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON pers TO GROUP pubdemo_user;

INSERT INTO meta_fields 
       VALUES ('pers','pers_desc', 'widget','area');
INSERT INTO meta_fields 
       VALUES ('pers','pers_home_address', 'widget','area');

COMMENT ON TABLE pers IS 'A Persons';
COMMENT ON COLUMN pers.pers_id IS 'ID';
COMMENT ON COLUMN pers.pers_hid IS 'Username';
COMMENT ON COLUMN pers.pers_first IS 'First Name';
COMMENT ON COLUMN pers.pers_last IS 'Last Name';
--COMMENT ON COLUMN pers.pers_sign IS 'Sign';
COMMENT ON COLUMN pers.pers_desc IS 'About';
--COMMENT ON COLUMN pers.pers_start IS 'Start';
--COMMENT ON COLUMN pers.pers_end IS 'End (Ex Employee)';
--COMMENT ON COLUMN pers.pers_office_phone IS 'Office Phone';
--COMMENT ON COLUMN pers.pers_office_room IS 'Office Room';
--COMMENT ON COLUMN pers.pers_home_phone IS 'Home Phone';
--COMMENT ON COLUMN pers.pers_mobile_phone IS 'Mobile Phone';

CREATE  OR REPLACE VIEW pers_combo AS
       SELECT pers_id AS id, 
	      (pers_hid || '--' || pers_last  || ', ' || pers_first) AS text 
       FROM pers
       ORDER BY pers_hid, pers_last, pers_first;

GRANT SELECT ON pers_combo TO GROUP pubdemo_user;


CREATE OR REPLACE FUNCTION pers_hid2id(NAME) returns int4
       AS 'SELECT pers_id FROM pers WHERE pers_hid = $1 ' STABLE LANGUAGE 'sql';

-- let access figure the current user 

-- CREATE OR REPLACE VIEW  current_pers AS
--    SELECT * from pers where pers_hid = current_user;

-- INSERT INTO meta_tables 
--     VALUES ('current_pers', 'hide','1');

-- GRANT SELECT ON current_pers TO GROUP pubdemo_user;




-- ##############################################################################
-- Publisher table.
-- ##############################################################################

CREATE TABLE publisher (
   publisher_id     SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
   publisher_name   TEXT NOT NULL CHECK (publisher_name != ''),   -- Publisher Name
   publisher_desc   TEXT NOT NULL CHECK (publisher_desc != '')   --  Description
) WITH OIDS;   


GRANT SELECT,UPDATE ON publisher_publisher_id_seq TO GROUP pubdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON publisher TO GROUP pubdemo_user;

COMMENT ON TABLE publisher IS 'B Publishers';
COMMENT ON COLUMN publisher.publisher_id IS 'ID';
COMMENT ON COLUMN publisher.publisher_name IS 'Name';
COMMENT ON COLUMN publisher.publisher_desc IS 'Description';


INSERT INTO meta_fields VALUES ('publisher','publisher_desc', 'widget','area');


-- #########################################################
-- PublicationType table. List of all types of publications.
-- #########################################################

CREATE TABLE pubty (
   pubty_id     SERIAL         NOT NULL PRIMARY KEY,                           -- Unique ID
   pubty_hid    VARCHAR(5)     NOT NULL CHECK (pubty_hid ~ '[A-Z]+') UNIQUE,   -- Human Readable Unique ID
   pubty_name   TEXT           NOT NULL CHECK (pubty_name != '')       -- Full Name of Work Type
) WITH OIDS;

GRANT SELECT,UPDATE ON pubty_pubty_id_seq TO GROUP pubdemo_admin;
GRANT SELECT ON pubty TO GROUP pubdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON pubty TO GROUP pubdemo_admin;

COMMENT ON TABLE pubty IS 'Z Publication Types';
COMMENT ON COLUMN pubty.pubty_id IS 'ID';
COMMENT ON COLUMN pubty.pubty_hid IS 'Type';
COMMENT ON COLUMN pubty.pubty_name IS 'Full Name';

CREATE OR REPLACE  VIEW pubty_combo AS
       SELECT pubty_id AS id, pubty_hid || '--' || pubty_name  AS text 
       FROM pubty ORDER BY pubty_hid;

GRANT SELECT ON pubty_combo TO GROUP pubdemo_user;

CREATE VIEW pubty_list AS
       SELECT pubty_id, pubty_hid, pubty_name
       FROM pubty;

GRANT SELECT ON pubty_list TO GROUP pubdemo_user;



-- ##################
-- Publication table.
-- ##################

CREATE TABLE pub (
   pub_id     SERIAL NOT NULL PRIMARY KEY,          -- Unique ID
   pub_date   DATE NOT NULL DEFAULT CURRENT_DATE,   -- Date of Entry
   pub_pers   INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user), -- Who created this entry
   pub_pubty   INT4 NOT NULL REFERENCES pubty,        -- Work Type
   pub_publisher  INT4 NOT NULL REFERENCES publisher, -- Publisher
   pub_desc   TEXT NOT NULL CHECK (pub_desc != ''),   -- Description of this publication
   pub_mod_date DATE,         			      -- last change
   pub_mod_user NAME				      -- by whom
) WITH OIDS;

GRANT SELECT,UPDATE ON pub_pub_id_seq TO GROUP pubdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON pub TO GROUP pubdemo_user;

COMMENT ON TABLE pub IS 'A Publications';
COMMENT ON COLUMN pub.pub_id IS 'ID';
COMMENT ON COLUMN pub.pub_date IS 'Date';
COMMENT ON COLUMN pub.pub_pers IS 'Creator';
COMMENT ON COLUMN pub.pub_pubty IS 'Type';
COMMENT ON COLUMN pub.pub_publisher IS 'Publisher';
COMMENT ON COLUMN pub.pub_desc IS 'Description';
COMMENT ON COLUMN pub.pub_mod_date IS 'Last changed';
COMMENT ON COLUMN pub.pub_mod_user IS 'Last change by';

CREATE INDEX pub_date_key ON pub (pub_date);
CREATE INDEX pub_pubty_key ON pub (pub_pubty);

INSERT INTO meta_fields 
       VALUES ('pub','pub_desc','widget','area');
INSERT INTO meta_fields 
       VALUES ('pub','pub_date','copy','1');
INSERT INTO meta_fields 
       VALUES ('pub','pub_pubty','copy','1');
INSERT INTO meta_fields 
       VALUES ('pub','pub_pers','copy','1');
INSERT INTO meta_fields 
       VALUES ('pub','pub_publisher','copy','1');
INSERT INTO "meta_fields"
       VALUES ('pub','pub_mod_date','widget','readonly');
INSERT INTO "meta_fields" 
       VALUES ('pub','pub_mod_user','widget','readonly');

DROP VIEW pub_list;
CREATE OR REPLACE VIEW pub_list AS
      SELECT pub_id, 
             pub_date,
	     pubty_hid AS pub_pubty,
--             nicetrim(pub_desc, 30) AS pub_desc  
	     pub_desc  
      FROM pub JOIN pubty     ON pub_pubty     = pubty_id
               JOIN pers      ON pub_pers      = pers_id
               JOIN publisher ON pub_publisher = publisher_id
      WHERE  (pers_hid=current_user OR ingroup('pubdemo_admin'));

COMMENT ON COLUMN pub_list.pub_id        IS 'ID';
COMMENT ON COLUMN pub_list.pub_date      IS 'Date';
COMMENT ON COLUMN pub_list.pub_pers      IS 'Creator';
COMMENT ON COLUMN pub_list.pub_pubty     IS 'Type';
COMMENT ON COLUMN pub_list.pub_publisher IS 'Publisher';
COMMENT ON COLUMN pub_list.pub_desc      IS 'Description';

GRANT SELECT ON pub_list TO GROUP pubdemo_user;

CREATE OR REPLACE FUNCTION pub_checker() RETURNS TRIGGER AS $$
BEGIN
   
    IF  NEW.pub_pers != pers_hid2id(current_user)
       AND  not ( ingroup('pubdemo_admin') )
    THEN
        RAISE EXCEPTION 'Do not change other peoples entries';
    END IF;

    NEW.pub_mod_date := CURRENT_DATE;
    NEW.pub_mod_user := getpgusername();

    IF TG_OP = 'DELETE' THEN
       RETURN OLD;
    ELSE
       RETURN NEW;
    END IF;
END; $$
LANGUAGE 'plpgsql';

CREATE TRIGGER pub_trigger BEFORE INSERT OR UPDATE OR DELETE ON pub FOR EACH ROW
  EXECUTE PROCEDURE pub_checker();


-- ####################
-- Conversion functions
-- ####################

DROP FUNCTION pers_id2hid(INT);
CREATE OR REPLACE FUNCTION pers_id2hid(INT) returns NAME
       AS 'SELECT pers_hid FROM pers WHERE pers_id = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION pubty_hid2id(NAME);
CREATE OR REPLACE FUNCTION pubty_hid2id(NAME) returns int4
       AS 'SELECT pubty_id FROM pubty WHERE pubty_hid = $1 ' STABLE 
LANGUAGE 'sql';

-- Initial test data

INSERT INTO gender (gender_hid, gender_name) VALUES
--       ('B', 'Both'),
       ('F', 'Female'),
       ('M', 'Male');

INSERT INTO pubty (pubty_hid, pubty_name) VALUES
       ('Journal', 'Article in a peer reviewed journal'),
       ('Proceedings', 'Article in conference proceedings'),
       ('Book',    'Complete book'),
       ('Book chapter', 'Chapter in a book');

INSERT INTO pers (pers_hid, pers_first, pers_last) VALUES
       ('zaucker', 'Fritz', 'Zaucker'),
       ('oetiker', 'Tobias', 'Oetiker'),
       ('moetiker', 'Manuel', 'Oetiker'),
       ('rplessl', 'Roman', 'Plessl'),
       ('pubtest', 'Test', 'User');

INSERT INTO publisher ( publisher_name, publisher_desc) VALUES
       ('Addison Wesley', 'xx'),
       ('American Geological Union', '');






       