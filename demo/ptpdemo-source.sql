-- #########################################################################
-- # SQL source for the PTP demo database ...
-- #########################################################################

-- #########################################################################
-- $Id: ptpdemo-source.sql 4206 2011-04-05 14:24:29Z oetiker $
-- Change Log
-- $Log: $

-- #########################################################################
-- Setup the database
-- ##########################################################################
CREATE GROUP ptpdemo_user;
CREATE GROUP ptpdemo_admin;
CREATE GROUP ptpdemo_reader;

CREATE USER ptpdemo        IN GROUP ptpdemo_admin,ptpdemo_user;
CREATE USER ptptest        IN GROUP ptpdemo_user PASSWORD 'ptptest';
CREATE USER ptpdemo_master IN GROUP ptpdemo_admin,ptpdemo_user;
CREATE USER ptpdemo_read   IN GROUP ptpdemo_reader;

DROP DATABASE ptpdemo;
CREATE DATABASE ptpdemo 
       WITH OWNER = ptpdemo 
       TEMPLATE = template0 
       ENCODING = 'UTF8';
GRANT ALL ON DATABASE ptpdemo TO ptpdemo;

\connect ptpdemo
COMMENT ON DATABASE ptpdemo IS 'ptpdemo';

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
GRANT  ALL   ON SCHEMA public  TO   ptpdemo;
GRANT  USAGE ON SCHEMA public  TO   GROUP ptpdemo_user;
GRANT  USAGE ON SCHEMA public  TO   GROUP ptpdemo_admin;
GRANT  USAGE ON SCHEMA public  TO   GROUP ptpdemo_reader;

REVOKE ALL   ON DATABASE ptpdemo FROM PUBLIC;
REVOKE ALL   ON SCHEMA   public  FROM PUBLIC;

-- let's loose our superior powers
SET SESSION AUTHORIZATION 'ptpdemo';

-- ###########################################################################


-- get list of our tables --> select * from pg_tables where tableowner='ptpdemo';

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

GRANT SELECT ON meta_fields TO GROUP ptpdemo_user;

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

GRANT SELECT ON meta_tables TO GROUP ptpdemo_user;


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


-- grant insert,update,select on ptp_config to group ptpdemo_admin;
-- grant select,update on ptp_config to group ptpdemo_user;

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

GRANT SELECT ON gender TO GROUP ptpdemo_user;
GRANT SELECT,UPDATE ON gender_gender_id_seq TO GROUP ptpdemo_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON gender TO GROUP ptpdemo_admin;

COMMENT ON TABLE gender IS 'Z Genders';
COMMENT ON COLUMN gender.gender_id IS 'ID';
COMMENT ON COLUMN gender.gender_hid IS 'Gender';
COMMENT ON COLUMN gender.gender_name IS 'Full Name';

CREATE OR REPLACE VIEW gender_combo AS
       SELECT gender_id AS id, gender_hid || ' -- ' || gender_name AS text FROM gender ORDER by gender_hid,gender_name;

GRANT SELECT ON gender_combo TO GROUP ptpdemo_user;

-- ##############################################################################
-- Pesonel table. Every worker is listed in this table
-- ##############################################################################

CREATE TABLE pers (
   pers_id     SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
   pers_hid    NAME NOT NULL UNIQUE,                    -- Human Readable Unique ID
   pers_first  TEXT NOT NULL CHECK (pers_first != ''),  -- First Name of Person
   pers_last   TEXT NOT NULL CHECK (pers_last != ''),   -- Last Name of Person
   pers_sign   VARCHAR(2),               				-- Ihr Zeichen
   pers_office_phone TEXT CHECK (pers_office_phone != ''), -- Office Phone Number
   pers_office_room  TEXT CHECK (pers_office_room  != ''), -- Office Room Number
   pers_home_phone TEXT CHECK (pers_home_phone != ''),  -- Home Phone Number
   pers_mobile_phone TEXT CHECK (pers_mobile_phone != ''),  -- Mobile Number
   pers_desc   TEXT CHECK (pers_desc != ''),             -- Explanation
   pers_start   DATE   NOT NULL DEFAULT CURRENT_DATE,       -- Is the person active'
   pers_end     DATE   CHECK ( pers_end is NULL or pers_end > pers_start )

) WITH OIDS;

GRANT SELECT,UPDATE ON pers_pers_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON pers TO GROUP ptpdemo_user;

INSERT INTO meta_fields 
       VALUES ('pers','pers_desc', 'widget','area');
INSERT INTO meta_fields 
       VALUES ('pers','pers_home_address', 'widget','area');

COMMENT ON TABLE pers IS 'Z Personnel';
COMMENT ON COLUMN pers.pers_id IS 'ID';
COMMENT ON COLUMN pers.pers_hid IS 'Username';
COMMENT ON COLUMN pers.pers_first IS 'First Name';
COMMENT ON COLUMN pers.pers_last IS 'Last Name';
COMMENT ON COLUMN pers.pers_sign IS 'Sign';
COMMENT ON COLUMN pers.pers_desc IS 'About';
COMMENT ON COLUMN pers.pers_start IS 'Start';
COMMENT ON COLUMN pers.pers_end IS 'End (Ex Employee)';
COMMENT ON COLUMN pers.pers_office_phone IS 'Office Phone';
COMMENT ON COLUMN pers.pers_office_room IS 'Office Room';
COMMENT ON COLUMN pers.pers_home_phone IS 'Home Phone';
COMMENT ON COLUMN pers.pers_mobile_phone IS 'Mobile Phone';

CREATE  OR REPLACE VIEW pers_combo AS
       SELECT pers_id AS id, 
	      (pers_hid || '--' || pers_last  || ', ' || pers_first) AS text 
       FROM pers
       WHERE pers_end IS NULL OR pers_end > current_date
       ORDER BY pers_hid, pers_last, pers_first;

GRANT SELECT ON pers_combo TO GROUP ptpdemo_user;


CREATE OR REPLACE FUNCTION pers_hid2id(NAME) returns int4
       AS 'SELECT pers_id FROM pers WHERE pers_hid = $1 ' STABLE LANGUAGE 'sql';

-- let access figure the current user 

-- CREATE OR REPLACE VIEW  current_pers AS
--    SELECT * from pers where pers_hid = current_user;

-- INSERT INTO meta_tables 
--     VALUES ('current_pers', 'hide','1');

-- GRANT SELECT ON current_pers TO GROUP ptpdemo_user;



-- -- ##############################################################################
-- -- Customer Table. The addresses of all our Customers
-- -- ##############################################################################

CREATE TABLE cust  (
   cust_id      SERIAL NOT NULL PRIMARY KEY,              -- Unique ID   
   cust_first   TEXT CHECK (cust_first != ''),          -- Firstname
   cust_last    TEXT NOT NULL CHECK (cust_last != ''), -- Lastname of Customer
   cust_gender  INT4 REFERENCES gender NOT NULL,       -- Gender of this person
   cust_desc    TEXT   CHECK (cust_desc != '') ,       -- Meta Info on Customer
   cust_pers    INT4   REFERENCES pers DEFAULT pers_hid2id(current_user),       -- Who is responsible for this customer
   cust_start   DATE   NOT NULL DEFAULT CURRENT_DATE,  -- Is the Customer Active
   cust_end     DATE   CHECK ( cust_end is NULL or cust_end > cust_start )
) WITH OIDS;

GRANT SELECT ON cust TO GROUP ptpdemo_reader;
GRANT SELECT,UPDATE ON cust_cust_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON cust TO GROUP ptpdemo_user;

INSERT INTO meta_fields 
       VALUES ('cust','cust_desc','widget','area');

COMMENT ON TABLE cust IS 'C Customers';
COMMENT ON COLUMN cust.cust_id IS 'ID';
COMMENT ON COLUMN cust.cust_first IS 'First Name';
COMMENT ON COLUMN cust.cust_last IS 'Last Name';
COMMENT ON COLUMN cust.cust_gender IS 'Gender';
COMMENT ON COLUMN cust.cust_desc IS 'Description';
COMMENT ON COLUMN cust.cust_pers IS 'Contact Owner';
COMMENT ON COLUMN cust.cust_start IS 'Start (First Contact)';
COMMENT ON COLUMN cust.cust_end IS 'End (Ex Customer)';

DROP VIEW cust_list;
CREATE OR REPLACE VIEW cust_list AS
       SELECT cust_id, 
	      cust_first, cust_last,
	      cust_start, cust_end,
              pers_hid as cust_pers
       FROM cust left join pers on (cust_pers = pers_id)
       ORDER by cust_last, cust_first;

COMMENT ON COLUMN cust_list.cust_first IS 'Firstname';
COMMENT ON COLUMN cust_list.cust_first IS 'Lastname';
COMMENT ON COLUMN cust_list.cust_pers  IS 'Contact owner';
COMMENT ON COLUMN cust_list.cust_start IS 'First contact';
COMMENT ON COLUMN cust_list.cust_start IS 'End (ex customer)';

GRANT SELECT ON cust_list TO GROUP ptpdemo_user;

DROP VIEW cust_combo;
CREATE OR REPLACE VIEW cust_combo AS
       SELECT cust_id AS id,
              (cust_id || '--' || cust_last || COALESCE(', ' 
	       || cust_first,'') ) || COALESCE('  ### ' || nicetrim(cust_desc,70),'') AS TEXT,
              cust_last || COALESCE(cust_first,'') AS meta_sort
              FROM cust
       WHERE cust_end IS NULL OR cust_end > CURRENT_DATE
       ORDER BY cust_last,cust_first;

GRANT SELECT ON cust_combo TO GROUP ptpdemo_user;


-- ####################################################
-- Contracts table. A Project can be part of a Contract
-- ####################################################
CREATE TABLE cntr (
  cntr_id      SERIAL NOT NULL PRIMARY KEY,             			 -- Unique ID
  cntr_hid     VARCHAR(6) NOT NULL UNIQUE CHECK ( cntr_hid ~ '^[-_0-9A-Za-z]+$'), -- Unique ID
  cntr_name    TEXT NOT NULL CHECK (cntr_name != ''),   			 -- Contract Name
  cntr_pers    INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user),  -- Contract Owner
  cntr_cust    INT4 NOT NULL REFERENCES cust,  -- Contract Owner
  cntr_start   DATE NOT NULL DEFAULT CURRENT_DATE,      			 -- Contract Start date
  cntr_end     DATE CHECK (cntr_end IS NULL or cntr_end > cntr_start),   	 -- Contract End date
  cntr_desc    TEXT CHECK (cntr_desc != '')   					     -- Contract Description
) WITH OIDS;   

GRANT SELECT,UPDATE ON cntr_cntr_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON cntr TO GROUP ptpdemo_user;

COMMENT ON TABLE  cntr IS 'C Contracts';
COMMENT ON COLUMN cntr.cntr_id        IS 'ID';
COMMENT ON COLUMN cntr.cntr_hid       IS 'Contract ID';
COMMENT ON COLUMN cntr.cntr_name      IS 'Name';
COMMENT ON COLUMN cntr.cntr_pers      IS 'Owner';
COMMENT ON COLUMN cntr.cntr_start     IS 'Start Date';
COMMENT ON COLUMN cntr.cntr_end       IS 'End Date';
COMMENT ON COLUMN cntr.cntr_desc      IS 'Description';

INSERT INTO meta_fields 
       VALUES ('cntr','cntr_desc', 'widget','area');

DROP VIEW cntr_list;
CREATE OR REPLACE VIEW cntr_list AS
       SELECT 
         cntr_id, cntr_hid, nicetrim(cntr_name,25) as cntr_name, pers_hid AS cntr_pers, 
         cust_last AS cntr_cust, 
	 cntr_start, cntr_end,         
         COALESCE(cntr_hid,' ') AS meta_sort         
       FROM cntr
            join pers ON (cntr_pers = pers_id)
            join cust ON (cntr_cust = cust_id)
; 

COMMENT ON COLUMN cntr_list.cntr_name     IS 'Contract';
COMMENT ON COLUMN cntr_list.cntr_id       IS 'Id';
COMMENT ON COLUMN cntr_list.cntr_hid      IS 'Number';
COMMENT ON COLUMN cntr_list.cntr_cust     IS 'Kunde';

GRANT SELECT ON cntr_list to group ptpdemo_user;          

DROP VIEW cntr_combo;
CREATE OR REPLACE VIEW cntr_combo AS
         SELECT cntr_id AS id,
--           pers_sign || ': ' ||
                 nicetrim(cntr_name,35) || ' [' || cntr_hid || '] ' AS text
                 FROM cntr join pers on (cntr_pers = pers_id) ORDER BY text;

GRANT SELECT ON cntr_combo to group ptpdemo_user;


-- ##############################################################################
-- Activity table.
-- ##############################################################################

CREATE TABLE acti (
   acti_id     SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
   acti_name   TEXT NOT NULL CHECK (acti_name != ''),   -- Activity Name
   acti_pers  INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user),           -- Who created this activity
   acti_desc   TEXT NOT NULL CHECK (acti_desc != '')   --  Description
) WITH OIDS;   


GRANT SELECT,UPDATE ON acti_acti_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON acti TO GROUP ptpdemo_user;

COMMENT ON TABLE acti IS 'B Activities';
COMMENT ON COLUMN acti.acti_id IS 'ID';
COMMENT ON COLUMN acti.acti_name IS 'Name';
COMMENT ON COLUMN acti.acti_pers IS 'Owner';
COMMENT ON COLUMN acti.acti_desc IS 'Description';


INSERT INTO meta_fields VALUES ('acti','acti_desc', 'widget','area');


DROP VIEW acti_list;
CREATE OR REPLACE VIEW acti_list AS
      SELECT acti_id,
             acti_name,
	     pers_hid as acti_pers,
	     nicetrim(acti_desc, 30) as acti_desc
      FROM pers JOIN acti ON(acti_pers = pers_id);

GRANT SELECT ON acti_list to group ptpdemo_user;

CREATE OR REPLACE VIEW acti_combo AS
        SELECT acti_id AS id,
               acti_name AS text	   
               FROM acti;

GRANT SELECT ON acti_combo to group ptpdemo_user;



-- ##############################################################################
-- WorkType table. List of all types of work we do including prices
-- ##############################################################################

CREATE TABLE woty (
   woty_id     SERIAL         NOT NULL PRIMARY KEY,                           -- Unique ID
   woty_hid    VARCHAR(5)        NOT NULL CHECK (woty_hid ~ '[A-Z]+') UNIQUE,   -- Human Readable Unique ID
   woty_name   TEXT           NOT NULL CHECK (woty_name != '')       -- Full Name of Work Type
) WITH OIDS;

GRANT SELECT,UPDATE ON woty_woty_id_seq TO GROUP ptpdemo_admin;
GRANT SELECT ON woty TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON woty TO GROUP ptpdemo_admin;

COMMENT ON TABLE woty IS 'Z Work Types';
COMMENT ON COLUMN woty.woty_id IS 'ID';
COMMENT ON COLUMN woty.woty_hid IS 'Type';
COMMENT ON COLUMN woty.woty_name IS 'Full Name';

CREATE OR REPLACE  VIEW woty_combo AS
       SELECT woty_id AS id, woty_hid || '--' || woty_name  AS text 
       FROM woty ORDER BY woty_hid;

GRANT SELECT ON woty_combo TO GROUP ptpdemo_user;

CREATE VIEW woty_list AS
       SELECT woty_id, woty_hid, woty_name
       FROM woty;

GRANT SELECT ON woty_list TO GROUP ptpdemo_user;



-- ##############################################################################
-- WorkLog table. All the work we do gets logged to this table.
-- ##############################################################################

CREATE TABLE wolo (
   wolo_id     SERIAL NOT NULL PRIMARY KEY,          -- Unique ID
   wolo_date   DATE NOT NULL DEFAULT CURRENT_DATE,   -- Date of Entry
   wolo_pers   INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user),        -- Who created this entry
   wolo_cntr   INT4 NOT NULL REFERENCES cntr,       -- Which Contract
   wolo_acti   INT4 NOT NULL REFERENCES acti,        -- Which Project was this for
   wolo_woty   INT4 NOT NULL REFERENCES woty,        -- Work Type
   wolo_val    decimal(9,2) NOT NULL,                -- How much of the type of work did we do
   wolo_desc   TEXT NOT NULL CHECK (wolo_desc != ''), -- Description of this task
   wolo_ref    VARCHAR(20),			     -- Reference to RT or for task numbers in projects
   wolo_mod_date DATE,         			     -- last change
   wolo_mod_user NAME				     -- by whom
) WITH OIDS;


GRANT SELECT,UPDATE ON wolo_wolo_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON wolo TO GROUP ptpdemo_user;

COMMENT ON TABLE wolo IS 'A Work Log';
COMMENT ON COLUMN wolo.wolo_id IS 'ID';
COMMENT ON COLUMN wolo.wolo_date IS 'Date';
COMMENT ON COLUMN wolo.wolo_pers IS 'Worker';
COMMENT ON COLUMN wolo.wolo_cntr IS 'Contract';
COMMENT ON COLUMN wolo.wolo_acti IS 'Activity';
COMMENT ON COLUMN wolo.wolo_woty IS 'W/C Type';
COMMENT ON COLUMN wolo.wolo_val  IS 'Amount';
COMMENT ON COLUMN wolo.wolo_desc IS 'Description';
COMMENT ON COLUMN wolo.wolo_ref  IS 'Ref';
COMMENT ON COLUMN wolo.wolo_mod_date IS 'Last changed';
COMMENT ON COLUMN wolo.wolo_mod_user IS 'Last change by';

CREATE INDEX wolo_date_key ON wolo (wolo_date);
CREATE INDEX wolo_pers_key ON wolo (wolo_pers);
CREATE INDEX wolo_acti_key ON wolo (wolo_acti);
CREATE INDEX wolo_cntr_key ON wolo (wolo_cntr);
CREATE INDEX wolo_woty_key ON wolo (wolo_woty);

INSERT INTO meta_fields 
       VALUES ('wolo','wolo_desc','widget','area');
INSERT INTO meta_fields 
       VALUES ('wolo','wolo_date','copy','1');
INSERT INTO meta_fields 
       VALUES ('wolo','wolo_cntr','copy','1');
INSERT INTO meta_fields 
       VALUES ('wolo','wolo_acti','copy','1');
INSERT INTO meta_fields 
       VALUES ('wolo','wolo_woty','copy','1');
INSERT INTO meta_fields 
       VALUES ('wolo','wolo_ref','order','8.5');
INSERT INTO "meta_fields"
       VALUES ('wolo','wolo_mod_date','widget','readonly');
INSERT INTO "meta_fields" 
       VALUES ('wolo','wolo_mod_user','widget','readonly');

DROP VIEW wolo_list;
CREATE OR REPLACE VIEW wolo_list AS
      SELECT wolo_id, 
             wolo_date,
             pers_hid AS wolo_pers,	
             cntr_name || ' [' || cntr_hid || ']' AS wolo_cntr,
	     acti_name || ' [' || acti_id || ']' AS wolo_acti,
	     woty_hid AS wolo_woty,
--             to_char(wolo_val,'FM9G999G990D00') || ' ' || unit_hid AS wolo_val,
             to_char(wolo_val,'FM9G999G990D00') AS wolo_val,
             wolo_ref,
-- Versuchsweise Anzeige vollstaendige Description (2.3.2009, Fritz)
--             nicetrim(wolo_desc, 30) AS wolo_desc  
         wolo_desc  
      FROM wolo,pers,woty,cntr,acti 	
      WHERE  (pers_hid=current_user OR ingroup('ptpdemo_admin')) 
	     AND wolo_pers = pers_id
             AND wolo_acti = acti_id
             AND wolo_cntr = cntr_id
             AND wolo_woty = woty_id;

COMMENT ON COLUMN wolo_list.wolo_id IS 'ID';
COMMENT ON COLUMN wolo_list.wolo_date IS 'Date';
COMMENT ON COLUMN wolo_list.wolo_pers IS 'Worker';
COMMENT ON COLUMN wolo_list.wolo_cntr IS 'Contract';
COMMENT ON COLUMN wolo_list.wolo_acti IS 'Activity';
COMMENT ON COLUMN wolo_list.wolo_woty IS 'W/C Type';
COMMENT ON COLUMN wolo_list.wolo_val  IS 'Amount';
COMMENT ON COLUMN wolo_list.wolo_desc IS 'Description';
COMMENT ON COLUMN wolo_list.wolo_ref  IS 'Ref';

GRANT SELECT ON wolo_list TO GROUP ptpdemo_user;

CREATE OR REPLACE FUNCTION wolo_checker() RETURNS TRIGGER AS $$
BEGIN
   
    IF TG_OP = 'UPDATE' OR TG_OP = 'INSERT' THEN 
      IF  NEW.wolo_pers != pers_hid2id(current_user)
         AND  not ( ingroup('ptpdemo_admin') )
       THEN
         RAISE EXCEPTION 'Do not change other peoples entries';
       END IF;

       IF exists ( SELECT cntr_id FROM cntr
                    WHERE NEW.wolo_cntr=cntr_id
		      AND ( NEW.wolo_date < cntr_start
			    OR NEW.wolo_date > cntr_end ))
       THEN
           RAISE EXCEPTION 'The selected contract is not valid for the selected date';
       END IF;

       NEW.wolo_mod_date := CURRENT_DATE;
       NEW.wolo_mod_user := getpgusername();

    END IF;

    IF TG_OP = 'UPDATE' or TG_OP = 'DELETE' THEN
       IF  OLD.wolo_pers != pers_hid2id(current_user)
         AND  not ( ingroup('ptpdemo_admin') )
       THEN
         RAISE EXCEPTION 'Do not change other peoples entries';
       END IF;

    END IF;    

    IF TG_OP = 'DELETE' THEN
       RETURN OLD;
    ELSE
       RETURN NEW;
    END IF;
END; $$
LANGUAGE 'plpgsql';

CREATE TRIGGER wolo_trigger BEFORE INSERT OR UPDATE OR DELETE ON wolo FOR EACH ROW
  EXECUTE PROCEDURE wolo_checker();

-- ##############################################################################
-- # Rules for other tables that are related to wolo
-- ##############################################################################

CREATE OR REPLACE RULE cntr_daterange_rule AS 
       ON UPDATE TO cntr
       WHERE EXISTS (SELECT wolo_id
              FROM wolo WHERE wolo_cntr = NEW.cntr_id
                          AND ( wolo_date < NEW.cntr_start OR wolo_date > NEW.cntr_end ))
       DO INSTEAD UPDATE elog set elog=false where elog('There would be worklog entries for this contract outside the new start/end range.');


-- ##############################################################################
-- Report views
-- ##############################################################################

CREATE or REPLACE VIEW daywork_rep AS
        SELECT wolo_date, pers_hid, sum(wolo_val) AS hours 
        FROM wolo, woty, pers 
       WHERE wolo_woty = woty_id 
	     AND wolo_pers = pers_id
             AND ( pers_hid = current_user OR ingroup('ptpdemo_admin')) 
       GROUP BY wolo_date, pers_hid
       ORDER BY wolo_date DESC;

GRANT SELECT ON daywork_rep TO GROUP ptpdemo_user;

COMMENT ON VIEW daywork_rep IS 'Daily hours from Work Log';
COMMENT ON COLUMN daywork_rep.wolo_date IS 'Date';
COMMENT ON COLUMN daywork_rep.pers_hid IS 'Pers';
COMMENT ON COLUMN daywork_rep.hours IS 'Hours';  



-- ####################
-- Conversion functions
-- ####################

DROP FUNCTION cntr_hid2id(NAME);
CREATE OR REPLACE FUNCTION cntr_hid2id(NAME) returns int4
       AS 'SELECT cntr_id FROM cntr WHERE cntr_hid = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION acti_name(INT);
CREATE OR REPLACE FUNCTION acti_name(INT) returns TEXT
       AS 'SELECT acti_name FROM acti WHERE acti_id = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION pers_id2hid(INT);
CREATE OR REPLACE FUNCTION pers_id2hid(INT) returns NAME
       AS 'SELECT pers_hid FROM pers WHERE pers_id = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION woty_hid2id(NAME);
CREATE OR REPLACE FUNCTION woty_hid2id(NAME) returns int4
       AS 'SELECT woty_id FROM woty WHERE woty_hid = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION pers_sign2id(NAME);
CREATE OR REPLACE FUNCTION pers_sign2idw(NAME) returns int4
       AS 'SELECT pers_id FROM pers WHERE pers_sign = $1 ' STABLE 
LANGUAGE 'sql';

-- Initial test data

INSERT INTO gender (gender_hid, gender_name) VALUES
--       ('B', 'Both'),
       ('F', 'Female'),
       ('M', 'Male');

INSERT INTO woty (woty_hid, woty_name) VALUES
       ('WORK', 'Working on a project'),
       ('PLAN', 'Planing a project');

INSERT INTO pers (pers_hid, pers_first, pers_last) VALUES
       ('zaucker', 'Fritz', 'Zaucker'),
       ('oetiker', 'Tobias', 'Oetiker'),
       ('moetiker', 'Manuel', 'Oetiker'),
       ('rplessl', 'Roman', 'Plessl'),
       ('ptptest', 'Test', 'User');

INSERT INTO acti (acti_name, acti_pers, acti_desc) VALUES
       ('SW dev',       3, 'Customized software'),
       ('Linux ops',    5, 'Linux system management and operations'),
       ('Websites ops', 4, 'Website operation and maintenance'),
       ('Websites dev', 1, 'Website design and implementation');


INSERT INTO cust (cust_first, cust_last, cust_gender, cust_pers, cust_start) VALUES
       ('John', 'Smith',  2, 3, '2011-01-01'),
       ('Mary', 'Miller', 1, 3, '2011-03-01');

INSERT INTO cntr (cntr_hid, cntr_name, cntr_pers, cntr_cust, cntr_start) VALUES
       ('1234', 'www.johnsmith.net', 2, 1, '2011-01-01'),
       ('1235', 'Linux@MM',          5, 2, '2011-02-01');





       