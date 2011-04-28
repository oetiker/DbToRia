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
CREATE GROUP ptpdemo_finance;
CREATE GROUP ptpdemo_reader;

CREATE USER ptpdemo IN GROUP ptpdemo_admin,ptpdemo_user;
CREATE USER ptpdemo_master IN GROUP ptpdemo_admin,ptpdemo_user;
CREATE USER ptp_read IN GROUP ptpdemo_reader;

DROP DATABASE ptpdemo;
CREATE DATABASE ptpdemo 
       WITH OWNER = ptpdemo 
       TEMPLATE = template0 
       ENCODING = 'UTF8';
GRANT ALL ON DATABASE ptpdemo TO ptpdemo;

\connect ptpdemo
COMMENT ON DATABASE ptpdemo IS 'ptpdemo';

-- our add the language

CREATE FUNCTION plpgsql_call_handler() returns language_handler
        as '$libdir/plpgsql.so' LANGUAGE 'C';

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

SET DateStyle TO 'European';

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
insert elog values (true);

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

CREATE AGGREGATE array_accum (anyelement)
(
    sfunc = array_append,
    stype = anyarray,
    initcond = '{}'
);

-- -- ## access 2010 insists on calling this function eventhough it does not exist
-- -- ## in postgresql ... so here it is and access 2010 is happy ...
-- CREATE OR REPLACE FUNCTION ident_current(name) RETURNS BIGINT AS $$
--    SELECT currval(regexp_replace($1,'.+public[."]+([^"]+)"?',E'\\1_\\1_id_seq')); 
-- $$ LANGUAGE SQL;
 

-- ############
-- store config information for ptp
-- ############

CREATE TABLE ptp_config (
   ptp_config_id    SERIAL NOT NULL PRIMARY KEY,
   ptp_config_hid   NAME    NOT NULL UNIQUE,
   ptp_config_value TEXT   NOT NULL,
   ptp_config_note  TEXT 
) WITH OIDS;


grant insert,update,select on ptp_config to group ptpdemo_admin;
grant select,update on ptp_config to group ptpdemo_user;

COMMENT ON TABLE ptp_config IS 'Z PTP Config Table';
COMMENT ON COLUMN ptp_config.ptp_config_id IS 'ID';
COMMENT ON COLUMN ptp_config.ptp_config_hid IS 'Key';
COMMENT ON COLUMN ptp_config.ptp_config_value IS 'Value';
COMMENT ON COLUMN ptp_config.ptp_config_note IS 'Note';
INSERT INTO meta_fields VALUES ('ptp_config','ptp_config_note', 'widget','area');


CREATE OR REPLACE FUNCTION get_ptp_config(NAME) RETURNS TEXT AS $$
select ptp_config_value
from ptp_config 
where ptp_config_hid = $1;
$$ LANGUAGE 'sql' IMMUTABLE;

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
-- Customer Table. The addresses of all our Customers
-- ##############################################################################

CREATE TABLE cust  (
   cust_id      SERIAL NOT NULL PRIMARY KEY,              -- Unique ID   
   cust_title   TEXT   CHECK (cust_title!= ''),           -- Any academic titles   
   cust_actitle TEXT CHECK (cust_actitle!= ''),         -- Academic Title
   cust_first   TEXT CHECK (cust_first != ''),          -- Firstname
   cust_last    TEXT NOT NULL CHECK (cust_last != ''), -- Lastname of Customer
   cust_gender  INT4 REFERENCES gender NOT NULL,       -- Gender of this person
   cust_du      BOOL,                                  -- sind wir 'per du'?
   cust_birthday DATE,                                 -- Customer'ss birthday
   cust_fc_date DATE,                                  -- When did we get to know them
   cust_fc_desc TEXT,                                  -- How did this contact happen
   cust_desc    TEXT   CHECK (cust_desc != '') ,       -- Meta Info on Customer
   cust_edu     TEXT,                                  -- Education
   cust_pers    INT4   REFERENCES pers DEFAULT pers_hid2id(current_user),       -- Who is responsible for this customer
   cust_start   DATE   NOT NULL DEFAULT CURRENT_DATE,  -- Is the Customer Active
   cust_end     DATE   CHECK ( cust_end is NULL or cust_end > cust_start )
) WITH OIDS;

GRANT SELECT ON cust TO GROUP ptpdemo_reader;
GRANT SELECT,UPDATE ON cust_cust_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON cust TO GROUP ptpdemo_user;

INSERT INTO meta_fields 
       VALUES ('cust','cust_desc','widget','area');

INSERT INTO meta_fields 
       VALUES ('cust','cust_fc_desc','widget','area');

COMMENT ON TABLE cust IS 'C Customers';
COMMENT ON COLUMN cust.cust_id IS 'ID';
COMMENT ON COLUMN cust.cust_title IS 'Anrede';
COMMENT ON COLUMN cust.cust_actitle IS 'Academic Title';
COMMENT ON COLUMN cust.cust_first IS 'First Name';
COMMENT ON COLUMN cust.cust_last IS 'Last Name';
COMMENT ON COLUMN cust.cust_gender IS 'Gender';
COMMENT ON COLUMN cust.cust_du  IS 'Duzis?';
COMMENT ON COLUMN cust.cust_birthday IS 'Birthday';
COMMENT ON COLUMN cust.cust_fc_date IS 'First Contact Date';
COMMENT ON COLUMN cust.cust_fc_desc IS 'First Contact Description';
COMMENT ON COLUMN cust.cust_desc IS 'Description';
COMMENT ON COLUMN cust.cust_edu IS 'Education';
COMMENT ON COLUMN cust.cust_pers IS 'OP Contact';
COMMENT ON COLUMN cust.cust_start IS 'Start (First Contact)';
COMMENT ON COLUMN cust.cust_end IS 'End (Ex Customer)';

DROP VIEW cust_list;
CREATE OR REPLACE VIEW cust_list AS
       SELECT cust_id, 
              cust_title,
              cust_actitle,
	      cust_first, cust_last,
	      cust_birthday,
	      cust_start, cust_end,
              pers_hid as cust_pers,
              ( select '<a target="ptp_crm" href="?search_field001=crm_id;search_value001=' || crm_id || ';table=crm;action=list">' || crm_date || '</a>' 
                from crm where crm_cust = cust_id and crm_crmt = 3 order by crm_date limit 1 ) as next_contact,
              '<a target="ptp_crm" href="?search_field001=cust_id;search_value001=' || cust_id || ';table=mlmbr;action=list">' 
                || m.ml || '</a>' as mailinglists
       FROM cust left join pers on (cust_pers = pers_id)
                 left join ( select mlmbr_cust as cust,array_to_string(array_accum(mlist_hid),', ') as ml  from mlmbr join mlist on (mlmbr_mlist = mlist_id) where (mlist_term is null or mlist_term >= current_date) group by mlmbr_cust ) as m on (cust_id = m.cust)
       ORDER by cust_last, cust_first;

COMMENT ON COLUMN cust_list.next_contact IS 'Next Cntct';

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


-- ##############################################################################
-- Pesonel table. Every worker is listed in this table
-- ##############################################################################

CREATE TABLE pers (
   pers_id     SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
   pers_hid    NAME NOT NULL UNIQUE,                    -- Human Readable Unique ID
   pers_first  TEXT NOT NULL CHECK (pers_first != ''),  -- First Name of Person
   pers_last   TEXT NOT NULL CHECK (pers_last != ''),   -- Last Name of Person
   pers_sign   VARCHAR(2),				-- Ihr Zeichen
   pers_fv     INT4 REFERENCES pers, 			-- Wer ist der FV dieses Mitarbeiters
   pers_virt   BOOLEAN NOT NULL DEFAULT false,          -- Does this person exist?
   pers_office_phone TEXT CHECK (pers_office_phone != ''), -- Office Phone Number
   pers_office_room  TEXT CHECK (pers_office_room  != ''), -- Office Room Number
   pers_home_phone TEXT CHECK (pers_home_phone != ''),  -- Home Phone Number
   pers_mobile_phone TEXT CHECK (pers_mobile_phone != ''),  -- Mobile Number
   pers_birthday DATE,                                  -- Birthday
   pers_home_address TEXT CHECK (pers_home_address != ''),  -- home address
   pers_desc   TEXT CHECK (pers_desc != ''),             -- Explanation
   pers_start   DATE   NOT NULL DEFAULT CURRENT_DATE,       -- Is the Customer Active'
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
COMMENT ON COLUMN pers.pers_fv IS 'FV';
COMMENT ON COLUMN pers.pers_virt IS 'Virtual';
COMMENT ON COLUMN pers.pers_start IS 'Start';
COMMENT ON COLUMN pers.pers_end IS 'End (Ex Employee)';
COMMENT ON COLUMN pers.pers_office_phone IS 'Office Phone';
COMMENT ON COLUMN pers.pers_office_room IS 'Office Room';
COMMENT ON COLUMN pers.pers_home_phone IS 'Home Phone';
COMMENT ON COLUMN pers.pers_mobile_phone IS 'Mobile Phone';
COMMENT ON COLUMN pers.pers_birthday IS 'Birthday';
COMMENT ON COLUMN pers.pers_home_address IS 'Home Address';

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

CREATE OR REPLACE VIEW  current_pers AS
   SELECT * from pers where pers_hid = current_user;

INSERT INTO meta_tables 
    VALUES ('current_pers', 'hide','1');

GRANT SELECT ON current_pers TO GROUP ptpdemo_user;


-- ####################################################
-- Contracts table. A Project can be part of a Contract
-- ####################################################
CREATE TABLE cntr (
  cntr_id      SERIAL NOT NULL PRIMARY KEY,             			 -- Unique ID
  cntr_hid     VARCHAR(6) NOT NULL UNIQUE CHECK ( cntr_hid ~ '^[-_0-9A-Za-z]+$') -- Unique ID
  cntr_name    TEXT NOT NULL CHECK (cntr_name != ''),   			 -- Contract Name
  cntr_pers    INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user),  -- Contract Owner
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
COMMENT ON COLUMN cntr.cntr_pers      IS 'Vendor';
COMMENT ON COLUMN cntr.cntr_address   IS 'Billing Address';
COMMENT ON COLUMN cntr.cntr_offer     IS 'Offer Date';
COMMENT ON COLUMN cntr.cntr_order     IS 'Order Date';
COMMENT ON COLUMN cntr.cntr_likely    IS 'Is likely';
COMMENT ON COLUMN cntr.cntr_start     IS 'Start Date';
COMMENT ON COLUMN cntr.cntr_end       IS 'End Date';
COMMENT ON COLUMN cntr.cntr_workstart IS 'Start of actual work';
COMMENT ON COLUMN cntr.cntr_workend   IS 'End of actual work';
COMMENT ON COLUMN cntr.cntr_remhrs    IS 'Hours to complete';
COMMENT ON COLUMN cntr.cntr_remdat    IS 'Date for hrs to cmpl';
COMMENT ON COLUMN cntr.cntr_desc      IS 'Description';
COMMENT ON COLUMN cntr.cntr_pool      IS 'Pool';
COMMENT ON COLUMN cntr.cntr_crnc      IS 'Currency';
COMMENT ON COLUMN cntr.cntr_hours     IS 'Hours offered';
COMMENT ON COLUMN cntr.cntr_value     IS 'Price offered';
COMMENT ON COLUMN cntr.cntr_expinc    IS 'Expense Inclusive';
COMMENT ON COLUMN cntr.cntr_mwst      IS 'Pays MwSt';
COMMENT ON COLUMN cntr.cntr_cntype    IS 'Contract Type';
COMMENT ON COLUMN cntr.cntr_expetype  IS 'FIBU Account';
COMMENT ON COLUMN cntr.cntr_expetype_old  IS 'FIBU Account before 2009';



INSERT INTO meta_fields 
       VALUES ('cntr','cntr_desc', 'widget','area');



DROP VIEW cntr_list;
CREATE OR REPLACE VIEW cntr_list AS
       SELECT 
         cntr_id, cntr_hid, pool_hid, nicetrim(cntr_name,25) as cntr_name, pers_hid AS cntr_pers, 
         cust_last AS cntr_cust, 
	 trunc(cntr_value,0) || ' ' || crnc_hid AS amount,
	 cntr_hours,
         case when cntr_hours > 0 then round(cntr_value / cntr_hours) end as planned_rate,
         case when hrs > 0 then round(cntr_value * passt / hrs) end  as real_rate,
	 cntr_start, cntr_offer, cntr_order, cntr_end,         
         CASE 
	   WHEN current_date < cntr_start 
	   THEN false 
	   WHEN current_date > cntr_end 
	   THEN false  
	   ELSE true 
         END AS active,
         CASE WHEN cntr_cntype in (1,2) THEN
	 CASE
	   WHEN cntr_end < current_date
           THEN CASE WHEN cntr_order IS NOT NULL THEN 'Completed' ELSE 'Failed' END
           ELSE CASE WHEN cntr_order IS NOT NULL 
                     THEN 'Ordered'
                     ELSE CASE WHEN cntr_offer IS NULL 
                               THEN 'Talking'
                               ELSE CASE WHEN cntr_likely 
                                         THEN 'Offered-Likely'
                                         ELSE 'Offered'
                                    END
                           END
                 END
          END ELSE 'Internal' END AS status,
         cntype_hid, cntr_mwst, expetype_hid, expetype_name,
         COALESCE(cntr_hid,' ') AS meta_sort         
       FROM ( select *,(current_date - cntr_start)::float / (cntr_end - cntr_start) as passt
              from cntr ) as c
            join pers ON (cntr_pers = pers_id)
            left outer join expetype on (cntr_expetype = expetype_id)
            join cust ON (cntr_cust = cust_id)
            join pool on (cntr_pool = pool_id)
            join cntype on (cntr_cntype = cntype_id)
            join crnc on (cntr_crnc = crnc_id)
            left outer join ( select cntr,sum(hrs) as hrs from icc_type where type in (1,2) group by cntr ) as h 
--                 on (cntr_id = cntr and cntr_end >= current_date and cntr_cntype in (1,2) and cntr_hours > 0); 
                 on (cntr_id = cntr and cntr_end >= current_date and cntr_cntype in (1,2)); 

COMMENT ON COLUMN cntr_list.cntr_name     IS 'Contract';
COMMENT ON COLUMN cntr_list.pool_hid      IS 'Pool';
COMMENT ON COLUMN cntr_list.active        IS 'Active';
COMMENT ON COLUMN cntr_list.amount        IS 'Total';
COMMENT ON COLUMN cntr_list.cntr_hours    IS 'Hours';
COMMENT ON COLUMN cntr_list.real_rate     IS 'R.Rate';
COMMENT ON COLUMN cntr_list.planned_rate     IS 'P.Rate';
COMMENT ON COLUMN cntr_list.status IS 'Status';
COMMENT ON COLUMN cntr_list.cntype_hid IS 'Type';
COMMENT ON COLUMN cntr_list.cntr_mwst IS 'MWST';
COMMENT ON COLUMN cntr_list.expetype_hid IS 'FIBU';
COMMENT ON COLUMN cntr_list.expetype_name IS 'FIBU Acct-Name';

GRANT SELECT ON cntr_list to group ptpdemo_user;          

DROP VIEW cntr_combo;
CREATE OR REPLACE VIEW cntr_combo AS
        SELECT cntr_id AS id,
                CASE WHEN current_date < cntr_start OR current_date > cntr_end   THEN '~ '
                ELSE ' ' END ||
                CASE 
                WHEN cntr_cntype = 1 THEN pers_sign || ' ba'                    
                WHEN cntr_cntype = 4 THEN pool_hid || ' gi'        
                WHEN cntr_cntype = 2 THEN pool_hid || ' po'        
                WHEN cntr_cntype = 3 THEN pool_hid || ' pi' 
                WHEN cntr_cntype = 5 THEN pers_sign || ' pe' 
                ELSE pool_hid || ' ' || cntr_cntype 
                END || ': ' ||
                nicetrim(cntr_name,35) || ' [' || cntr_hid || '] ' AS text
                FROM cntr join pool on (cntr_pool=pool_id) join pers on (cntr_pers = pers_id) ORDER BY text;

GRANT SELECT ON cntr_combo to group ptpdemo_user;


-- ##############################################################################
-- Activity table.
-- ##############################################################################

CREATE TABLE acti (
   acti_id     SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
   acti_name   TEXT NOT NULL CHECK (acti_name != ''),   -- Activity Name
   acti_pers  INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user),           -- Who created this activity
   acti_prod   INT4 NOT NULL REFERENCES prod,           -- Part of which Product
   acti_mwst   REAL NOT NULL DEFAULT 7.6,               -- How much Mehrwertsteuer is due for this activity
   acti_start  DATE NOT NULL DEFAULT CURRENT_DATE,      -- Start date
   acti_end    DATE CHECK (acti_end IS NULL or acti_end > acti_start),   -- End date
   acti_expe   BOOLEAN DEFAULT false,                  -- used only for expenses, no hours!
   acti_acct   INT REFERENCES expetype(expetype_id),   -- Account Number for Spesen
   acti_desc   TEXT NOT NULL CHECK (acti_desc != '')   --  Description
) WITH OIDS;   


GRANT SELECT,UPDATE ON acti_acti_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON acti TO GROUP ptpdemo_user;

COMMENT ON TABLE acti IS 'B Activities';
COMMENT ON COLUMN acti.acti_id IS 'ID';
COMMENT ON COLUMN acti.acti_name IS 'Name';
COMMENT ON COLUMN acti.acti_pers IS 'Owner';
COMMENT ON COLUMN acti.acti_prod IS 'Product';
COMMENT ON COLUMN acti.acti_mwst IS 'MwSt';
COMMENT ON COLUMN acti.acti_start IS 'Start Date';
COMMENT ON COLUMN acti.acti_end IS 'End Date';
COMMENT ON COLUMN acti.acti_acct IS 'Account Number';
COMMENT ON COLUMN acti.acti_desc IS 'Description';
COMMENT ON COLUMN acti.acti_acct IS 'FIBU Account';
COMMENT ON COLUMN acti.acti_expe IS 'Expenses only';


INSERT INTO meta_fields VALUES ('acti','acti_desc', 'widget','area');
INSERT INTO meta_fields VALUES ('acti','acti_prod', 'copy','1');



DROP VIEW acti_list;
CREATE OR REPLACE VIEW acti_list AS
      SELECT acti_id,
             acti_name,
	     pers_hid as acti_pers,
             CASE 
             WHEN current_date < prod_start OR current_date > prod_end THEN '~ ' 
             ELSE '' END || 
	     wap.workarea_hid || ' ' || 
             prod_name || ' [' || prod_id || ']' as acti_prod,
             acti_mwst,
	     acti_start,
             acti_end,
             CASE 
	     WHEN current_date < acti_start THEN false 
             WHEN current_date > acti_end THEN false  
             ELSE true END as active,
	     nicetrim(acti_desc, 30) as acti_desc,
         acti_expe, 
	     expetype_hid
      FROM pers JOIN acti ON(acti_pers = pers_id) 
		JOIN prod ON(acti_prod = prod_id)
		JOIN workarea as wap ON(prod_workarea = wap.workarea_id)  
		LEFT OUTER JOIN expetype ON (acti_acct = expetype_id);

GRANT SELECT ON acti_list to group ptpdemo_user;
COMMENT ON COLUMN acti_list.active IS 'Active';

CREATE OR REPLACE VIEW acti_combo AS
        SELECT acti_id AS id,
	       CASE WHEN current_date < acti_start OR current_date > acti_end THEN '~ '
                    WHEN EXISTS (select prodpers_id from prodpers,pers 
                          where pers_id = prodpers_pers AND  pers_hid = current_user AND
	                  prodpers_prod = acti_prod ) 
                          THEN 'S ' ELSE '? ' END || ' - ' ||
               workarea_hid || '/' ||  acti_id || ' ' || acti_name AS text,	   
	       CASE WHEN current_date < acti_start OR current_date > acti_end THEN 'C '
                    WHEN EXISTS (select prodpers_id from prodpers,pers 
                          where pers_id = prodpers_pers AND  pers_hid = current_user AND
	                  prodpers_prod = acti_prod ) 
                          THEN 'A ' ELSE 'B ' END || 
	                  workarea_hid || acti_id AS meta_sort
               FROM workarea, acti,prod
               WHERE acti_prod = prod_id and 
                     prod_workarea=workarea_id
                ORDER by meta_sort;

GRANT SELECT ON acti_combo to group ptpdemo_user;



-- ##############################################################################
-- WorkType table. List of all types of work we do including prices
-- ##############################################################################

CREATE TABLE woty (
   woty_id     SERIAL         NOT NULL PRIMARY KEY,                           -- Unique ID
   woty_hid    VARCHAR(5)        NOT NULL CHECK (woty_hid ~ '[A-Z]+') UNIQUE,   -- Human Readable Unique ID
   woty_name   TEXT           NOT NULL CHECK (woty_name != ''),       -- Full Name of Work Type
   woty_unit    INT4          NOT NULL REFERENCES unit       -- Unit types
) WITH OIDS;

GRANT SELECT,UPDATE ON woty_woty_id_seq TO GROUP ptpdemo_admin;
GRANT SELECT ON woty TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON woty TO GROUP ptpdemo_admin;

COMMENT ON TABLE woty IS 'Z Work Types';
COMMENT ON COLUMN woty.woty_id IS 'ID';
COMMENT ON COLUMN woty.woty_hid IS 'Type';
COMMENT ON COLUMN woty.woty_name IS 'Full Name';
COMMENT ON COLUMN woty.woty_unit IS 'Unit';

CREATE OR REPLACE  VIEW woty_combo AS
       SELECT woty_id AS id, woty_hid || '--' || woty_name || ' / ' || unit_hid AS text 
       FROM woty,unit WHERE woty_unit=unit_id ORDER BY woty_hid;

GRANT SELECT ON woty_combo TO GROUP ptpdemo_user;

CREATE VIEW woty_list AS
       SELECT woty_id, woty_hid, woty_name, unit_name
       FROM woty,unit WHERE woty_unit=unit_id;

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
   wolo_invoice INT4 REFERENCES invoice DEFAULT NULL      -- If this entry has been billed Description of this task
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
COMMENT ON COLUMN wolo.wolo_invoice IS 'Invoice';
COMMENT ON COLUMN wolo.wolo_mod_date IS 'Geändert am';
COMMENT ON COLUMN wolo.wolo_mod_user IS 'Geändert von';

CREATE INDEX wolo_date_key ON wolo (wolo_date);
CREATE INDEX wolo_pers_key ON wolo (wolo_pers);
CREATE INDEX wolo_acti_key ON wolo (wolo_acti);
CREATE INDEX wolo_cntr_key ON wolo (wolo_cntr);
CREATE INDEX wolo_woty_key ON wolo (wolo_woty);
CREATE INDEX wolo_invoice_key ON wolo (wolo_invoice);

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
INSERT INTO meta_fields 
       VALUES ('wolo','wolo_invoice','widget','readonly');
INSERT INTO "meta_fields"
       VALUES ('wolo','wolo_mod_date','widget','readonly');
INSERT INTO "meta_fields" 
       VALUES ('wolo','wolo_mod_user','widget','readonly');

-- Combo-box only with subscribed projects
INSERT INTO meta_fields 
       VALUES ('wolo','wolo_acti','widget','idcombo(ref=acti,combo=acti_subscribed_combo)');
INSERT INTO meta_fields
       VALUES ('wolo','wolo_cntr','widget','hidcombo(ref=cntr,combo=cntr_active_combo)');

DROP VIEW wolo_list;
CREATE OR REPLACE VIEW wolo_list AS
      SELECT wolo_id, 
             wolo_date,
             pers_hid AS wolo_pers,	
             cntr_name || ' [' || cntr_hid || ']' AS wolo_cntr,
	     acti_name || ' [' || acti_id || ']' AS wolo_acti,
	     woty_hid AS wolo_woty,
             to_char(wolo_val,'FM9G999G990D00') || ' ' || unit_hid AS wolo_val,
             ( select pool_hid from pool where pool_id = cntr_pool ) AS cntr_pool,
             wolo_ref,
	     case 
	     when wolo_id in (select  expe_wolo from expe)
	     then
		 -- 'beleg'::text
 	 	 (select expetype_hid from expe,expetype where expe_expetype=expetype_id and expe_wolo=wolo_id)
             else
-- 	       expetype_hid
                 null
 	     end as account,
-- Versuchsweise Anzeige vollstaendige Description (2.3.2009, Fritz)
--             nicetrim(wolo_desc, 30) AS wolo_desc  
         wolo_desc  
      FROM wolo,pers,prod,woty,unit,cntr,acti 	
--	   LEFT OUTER JOIN expetype ON (acti_acct = expetype_id)
      WHERE  (pers_hid=current_user OR ingroup('ptpdemo_admin')) 
	     AND wolo_pers = pers_id
             AND wolo_acti = acti_id
             AND acti_prod = prod_id
             AND wolo_cntr = cntr_id
             AND wolo_woty = woty_id
             AND woty_unit = unit_id;

GRANT SELECT ON wolo_list TO GROUP ptpdemo_user;
COMMENT ON COLUMN wolo_list.account IS 'FIBU';


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

CREATE OR REPLACE RULE acti_daterange_rule AS 
       ON UPDATE TO acti
       WHERE EXISTS (SELECT wolo_id
              FROM wolo WHERE wolo_acti = NEW.acti_id 
                         AND ( wolo_date < NEW.acti_start OR wolo_date > NEW.acti_end ))
       DO INSTEAD UPDATE elog set elog=false where elog('There would be worklog entries, pointing to this activity outside the new start/end range');

CREATE OR REPLACE RULE acti_daterange_pf_ins_rule AS 
       ON INSERT TO acti
       WHERE EXISTS (SELECT prod_id
                     FROM prod 
                     WHERE NEW.acti_prod = prod_id  
                           AND ( NEW.acti_start < prod_start
                              OR NEW.acti_end   > prod_end ))
       DO INSTEAD UPDATE elog set elog=false where  elog('The activities start or end date is outside the valid range of either its parent product or function/project');

CREATE OR REPLACE RULE acti_daterange_pf_upd_rule AS 
       ON UPDATE TO acti
       WHERE EXISTS (SELECT prod_id
                     FROM prod
                     WHERE NEW.acti_prod = prod_id
                           AND ( NEW.acti_start < prod_start
                              OR NEW.acti_end   > prod_end ))
       DO INSTEAD  UPDATE elog set elog=false where  elog('The activities start or end date is outside the valid range of either its parent product or function/project');


-- ##############################################################################
-- Report views
-- ##############################################################################

CREATE or REPLACE VIEW daywork_rep AS
        SELECT wolo_date, pers_hid, sum(wolo_val) AS hours 
        FROM wolo, woty, unit, pers 
       WHERE wolo_woty = woty_id 
             AND woty_unit = unit_id
             AND unit_hid = 'hrs'
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

DROP FUNCTION pool_hid2id(NAME);
CREATE OR REPLACE FUNCTION pool_hid2id(NAME) returns int4
       AS 'SELECT pool_id FROM pool WHERE cntr_hid = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION pool_id2hid(INT);
CREATE OR REPLACE FUNCTION pool_id2hid(INT) returns CHAR(4)
       AS 'SELECT pool_hid FROM pool WHERE pool_id = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION cntr_hid2id(NAME);
CREATE OR REPLACE FUNCTION cntr_hid2id(NAME) returns int4
       AS 'SELECT cntr_id FROM cntr WHERE cntr_hid = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION expetype_hid2id(NAME);
CREATE OR REPLACE FUNCTION expetype_hid2id(NAME) returns int4
       AS 'SELECT expetype_id FROM expetype WHERE expetype_hid = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION prod_name(INT);
CREATE OR REPLACE FUNCTION prod_name(INT) returns TEXT
       AS 'SELECT prod_name FROM prod WHERE prod_id = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION acti_name(INT);
CREATE OR REPLACE FUNCTION acti_name(INT) returns TEXT
       AS 'SELECT acti_name FROM acti WHERE acti_id = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION pers_id2hid(INT);
CREATE OR REPLACE FUNCTION pers_id2hid(INT) returns NAME
       AS 'SELECT pers_hid FROM pers WHERE pers_id = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION cntrstate_hid2id(NAME);
CREATE OR REPLACE FUNCTION cntrstate_hid2id(NAME) returns int4
   AS 'SELECT cntrstate_id FROM cntrstate WHERE cntrstate_hid = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION woty_hid2id(NAME);
CREATE OR REPLACE FUNCTION woty_hid2id(NAME) returns int4
       AS 'SELECT woty_id FROM woty WHERE woty_hid = $1 ' STABLE 
LANGUAGE 'sql';

DROP FUNCTION pers_sign2id(NAME);
CREATE OR REPLACE FUNCTION pers_sign2idw(NAME) returns int4
       AS 'SELECT pers_id FROM pers WHERE pers_sign = $1 ' STABLE 
LANGUAGE 'sql';

