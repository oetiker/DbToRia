-- #########################################################################
-- # SQL source for the PTP2 database ...
-- #########################################################################

-- #########################################################################
-- $Id: ptp2-source.sql 4206 2011-04-05 14:24:29Z oetiker $
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

DROP DATABASE ptpdemo2;
CREATE DATABASE ptpdemo2 
       WITH OWNER = ptpdemo 
       TEMPLATE = template0 
       ENCODING = 'LATIN1';
GRANT ALL ON DATABASE ptpdemo2 TO ptpdemo;

\connect ptpdemo2
COMMENT ON DATABASE ptpdemo2 IS 'ptpdemo2';

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

REVOKE ALL   ON DATABASE ptpdemo2   FROM PUBLIC;
REVOKE ALL   ON SCHEMA   public  FROM PUBLIC;

-- let's loose our superior powers
SET SESSION AUTHORIZATION 'ptpdemo';

-- ###########################################################################


-- get list of our tables --> select * from pg_tables where tableowner='ptpdemo';

SET DateStyle TO 'European';


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

-- ## access 2010 insists on calling this function eventhough it does not exist
-- ## in postgresql ... so here it is and access 2010 is happy ...
CREATE OR REPLACE FUNCTION ident_current(name) RETURNS BIGINT AS $$
   SELECT currval(regexp_replace($1,'.+public[."]+([^"]+)"?',E'\\1_\\1_id_seq')); 
$$ LANGUAGE SQL;
 

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
-- Cyber Adress Types
-- ##############################################################################

DROP TABLE catype;
DROP SEQUENCE catype_catype_id_seq;

CREATE TABLE catype (
   catype_id   SERIAL NOT NULL PRIMARY KEY,           -- Unique ID
   catype_hid  VARCHAR(5) NOT NULL UNIQUE,            -- Human Readable Unique ID
   catype_name TEXT NOT NULL CHECK (catype_name != '')  -- Full Name of catype
) WITH OIDS;

GRANT SELECT ON catype TO GROUP ptpdemo_user,ptpdemo_reader;
GRANT SELECT,UPDATE ON catype_catype_id_seq TO GROUP ptpdemo_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON catype TO GROUP ptpdemo_admin;

COMMENT ON TABLE catype IS 'Z Cyber Address Type';
COMMENT ON COLUMN catype.catype_id IS 'ID';
COMMENT ON COLUMN catype.catype_hid IS 'Short Name';
COMMENT ON COLUMN catype.catype_name IS 'Long Name';

DROP VIEW catype_combo;
CREATE OR REPLACE VIEW catype_combo AS
       SELECT catype_id AS id, catype_hid || ' -- ' || catype_name AS text 
       FROM catype ORDER by catype_hid, catype_name ;

GRANT SELECT ON catype_combo TO GROUP ptpdemo_user;

-- ##############################################################################
-- Currencies
-- ##############################################################################

DROP TABLE crnc;
DROP SEQUENCE crnc_crnc_id_seq;

CREATE TABLE crnc (
   crnc_id     SERIAL NOT NULL PRIMARY KEY,     -- Unique ID
   crnc_hid    VARCHAR(5) NOT NULL UNIQUE,      -- Human Readable Unique ID
   crnc_name   TEXT NOT NULL,   		-- Full Name of catype
   crnc_rate   DECIMAL(9,3) NOT NULL,
   crnc_invc   TEXT NOT NULL,   		-- Comment for Invoice
   crnc_last   DATE DEFAULT CURRENT_DATE
) WITH OIDS;

GRANT SELECT,UPDATE ON crnc_crnc_id_seq TO GROUP ptpdemo_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON crnc TO GROUP ptpdemo_user;

CREATE OR REPLACE FUNCTION crnc_hid2id(NAME) RETURNS int4
       AS 'SELECT crnc_id FROM crnc WHERE crnc_hid = $1 ' 
       STABLE LANGUAGE 'sql';


INSERT INTO meta_fields 
       VALUES ('crnc','crnc_invc','widget','area');

COMMENT ON TABLE crnc IS 'Z Currencies and Exchangerates';
COMMENT ON COLUMN crnc.crnc_id IS   'ID';
COMMENT ON COLUMN crnc.crnc_hid IS  'Symbol';
COMMENT ON COLUMN crnc.crnc_name IS 'Name';
COMMENT ON COLUMN crnc.crnc_rate IS 'Exchange Rate';
COMMENT ON COLUMN crnc.crnc_last IS 'Last Update';
COMMENT ON COLUMN crnc.crnc_invc IS 'Invoice Comment';

DROP VIEW crnc_combo;
CREATE OR REPLACE VIEW crnc_combo AS
       SELECT crnc_id AS id, crnc_hid || ' -- ' || crnc_name AS text 
       FROM crnc ORDER BY crnc_hid,crnc_name ;

GRANT SELECT ON crnc_combo TO GROUP ptpdemo_user;

CREATE OR REPLACE VIEW cust_combo AS
       SELECT cust_id AS id,
              (cust_id || '--' || cust_last || COALESCE(', ' || cust_first,'') ) AS TEXT, 
              cust_last || COALESCE(cust_first,'') AS meta_sort
              FROM cust
       WHERE cust_end IS NULL OR cust_end > CURRENT_DATE
       ORDER BY cust_last,cust_first;


-- ##############################################################################
-- Street Adress Types
-- ##############################################################################

DROP TABLE addrtype;
DROP SEQUENCE addrtype_addrtype_id_seq;

CREATE TABLE addrtype (
   addrtype_id   SERIAL NOT NULL PRIMARY KEY,              -- Unique ID
   addrtype_hid  VARCHAR(5) NOT NULL UNIQUE,               -- Human Readable Unique ID
   addrtype_name TEXT NOT NULL CHECK (addrtype_name != '') -- Full Name of addrtype
) WITH OIDS;

GRANT SELECT ON addrtype TO GROUP ptpdemo_user, ptpdemo_reader;
GRANT SELECT,UPDATE ON addrtype_addrtype_id_seq TO GROUP ptpdemo_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON addrtype TO GROUP ptpdemo_admin;

COMMENT ON TABLE addrtype IS 'Z Street Address Type';
COMMENT ON COLUMN addrtype.addrtype_id IS 'ID';
COMMENT ON COLUMN addrtype.addrtype_hid IS 'Short Name';
COMMENT ON COLUMN addrtype.addrtype_name IS 'Long Name';

DROP VIEW addrtype_combo;
CREATE OR REPLACE VIEW addrtype_combo AS
       SELECT addrtype_id AS id, addrtype_hid || ' -- ' || addrtype_name AS text 
        FROM addrtype ORDER BY addrtype_hid , addrtype_name;

GRANT SELECT ON addrtype_combo TO GROUP ptpdemo_user;


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

DROP VIEW cust_lonely_rep;
CREATE OR REPLACE VIEW cust_lonely_rep AS (
	SELECT cust_id, cust_last, cust_first,pers_hid  
	FROM cust left join pers ON (cust_pers=pers_id) 
	WHERE cust_end IS NULL 
          AND cust_id NOT IN (SELECT mlmbr_cust FROM mlmbr) 
        ORDER BY cust_last
); 
GRANT SELECT ON cust_lonely_rep TO GROUP ptpdemo_user;
COMMENT ON VIEW cust_lonely_rep IS 'Customers without mailing list entry';
COMMENT ON COLUMN cust_lonely_rep.pers_hid IS 'O+P Resonsible';
  

DROP VIEW cust_very_lonely_rep;
CREATE OR REPLACE VIEW cust_very_lonely_rep AS (
	SELECT cust_id, cust_last, cust_first 
	FROM cust
	WHERE cust_end IS NULL 
          AND cust_pers IS NULL
        ORDER BY cust_last
); 
GRANT SELECT ON cust_very_lonely_rep TO GROUP ptpdemo_user;
COMMENT ON VIEW cust_very_lonely_rep IS 'Customers without O+P Responsible';
-- COMMENT ON COLUMN cust_very_lonely_rep.pers_hid IS 'O+P Resonsible';

CREATE OR REPLACE VIEW cust_duplicates_rep AS (
	SELECT c1.cust_id AS cid1, c1.cust_last AS cl1, c1.cust_first AS cf1, 
	       c2.cust_id AS cid2, c2.cust_last AS cl2, c2.cust_first AS cf2 
	FROM cust AS c1, cust AS c2 
	WHERE c1.cust_id<>c2.cust_id 
	 AND c1.cust_last=c2.cust_last 
	 AND c1.cust_first=c2.cust_first
        ORDER BY c1.cust_last, c1.cust_first
);
GRANT SELECT ON cust_duplicates_rep TO GROUP ptpdemo_user;
COMMENT ON VIEW cust_duplicates_rep IS 'Customers with possibly duplicated entries';
-- COMMENT ON COLUMN cust_lonely_rep.pers_hid IS 'O+P Resonsible';


DROP TABLE address;   
DROP SEQUENCE address_address_id_seq;    

CREATE TABLE address  (   
  address_id      SERIAL NOT NULL PRIMARY KEY,              -- Unique ID       
  address_cust    INT4 REFERENCES cust NOT NULL ON DELETE CASCADE,      -- Whos address is this ?
  address_addrtype INT4 REFERENCES addrtype  NOT NULL,  -- What type of address is this?
  address_func    TEXT   ,
  address_company TEXT   ,
  address_street  TEXT   ,
  address_zip     TEXT   ,
  address_town    TEXT   ,
  address_country TEXT   ,
  address_invalid DATE   ,
  address_importance INT  NOT NULL DEFAULT 0              -- How important is this address (the more the import)
) WITH OIDS;

GRANT SELECT,UPDATE ON address_address_id_seq TO GROUP ptpdemo_user;
GRANT SELECT ON address TO GROUP ptpdemo_reader;
GRANT SELECT,INSERT,UPDATE,DELETE ON address TO GROUP ptpdemo_user;

COMMENT ON TABLE address IS 'C Physical Address';
COMMENT ON COLUMN address.address_id IS 'ID';
COMMENT ON COLUMN address.address_cust IS 'Customer';
COMMENT ON COLUMN address.address_addrtype IS 'Type';
COMMENT ON COLUMN address.address_func IS 'Function';
COMMENT ON COLUMN address.address_company IS 'Company';
COMMENT ON COLUMN address.address_street IS 'Street';
COMMENT ON COLUMN address.address_zip IS 'ZIP';
COMMENT ON COLUMN address.address_town IS 'Town';
COMMENT ON COLUMN address.address_country IS 'Country';
COMMENT ON COLUMN address.address_importance IS 'Importance';
COMMENT ON COLUMN address.address_invalid IS 'Invalid Since';


INSERT INTO meta_fields 
       VALUES ('address','address_company','widget','area');
INSERT INTO meta_fields 
       VALUES ('address','address_street','widget','area');

DROP VIEW address_list;
CREATE OR REPLACE VIEW address_list AS
       SELECT address_id, -- address_hid, 
             cust_last || ', ' || cust_first as cust_last, addrtype_hid,
              address_company, address_street, address_zip, address_town , address_country, address_importance, address_invalid
       FROM address, cust, addrtype
       WHERE address_cust = cust_id 
        AND  address_addrtype = addrtype_id;

GRANT SELECT ON address_list TO GROUP ptpdemo_user;

DROP VIEW address_combo;
CREATE OR REPLACE VIEW address_combo AS
       SELECT address_id AS id, 
              cust_id || ' -  ' || cust_last || ', '
              || CASE WHEN address_invalid < CURRENT_DATE
                   THEN 'INVALID ADDRESS!' ELSE '' END 
	      || COALESCE(address_company || ', ','')
              || COALESCE(address_street || ', ','No Street') 
              || COALESCE(address_zip || ' ','') 
              || COALESCE(address_town,'No Town')
              || COALESCE(', ' || address_country,'')
              || ' [' || addrtype_hid || ']' AS text,    
              cust_id AS meta_sort 
       FROM address,addrtype,cust 
       WHERE address_addrtype = addrtype_id AND address_cust=cust_id
       ORDER BY cust_id ,cust_last;

GRANT SELECT ON address_combo TO GROUP ptpdemo_user;


-- -----------------------------------------------------------------------

DROP TABLE cyberaddr;
DROP SEQUENCE cyberaddr_cyberaddr_id_seq;

CREATE TABLE cyberaddr  (
   cyberaddr_id      SERIAL NOT NULL PRIMARY KEY,                         -- Unique ID   
   cyberaddr_cust    INT4   REFERENCES cust NOT NULL ON DELETE CASCADE,   -- Whos address is this ?
   cyberaddr_catype  INT4   REFERENCES catype NOT NULL, -- What type of address is this?
   cyberaddr_address INT4   REFERENCES address,         -- Optional Link to physical location
   cyberaddr_url     TEXT   NOT NULL,                   -- The actual Address
   cyberaddr_importance  INT    NOT NULL DEFAULT 0      -- How important is this address (the more the important)?
) WITH OIDS;

GRANT SELECT ON cyberaddr TO GROUP ptpdemo_reader;
GRANT SELECT,UPDATE ON cyberaddr_cyberaddr_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON cyberaddr TO GROUP ptpdemo_user;

COMMENT ON TABLE cyberaddr IS 'C Cyber Address';
COMMENT ON COLUMN cyberaddr.cyberaddr_id IS 'ID';
COMMENT ON COLUMN cyberaddr.cyberaddr_cust IS 'Customer';
COMMENT ON COLUMN cyberaddr.cyberaddr_catype IS 'Type';
COMMENT ON COLUMN cyberaddr.cyberaddr_address IS 'Physical Location';
COMMENT ON COLUMN cyberaddr.cyberaddr_url IS 'Address/URL';
COMMENT ON COLUMN cyberaddr.cyberaddr_importance IS 'Importance';

CREATE OR REPLACE RULE cyberaddr_custaddress_ins_rule AS
       ON INSERT TO cyberaddr      
       WHERE NEW.cyberaddr_address IS NOT NULL
             AND NOT EXISTS (SELECT 1
                         FROM address 
                         WHERE NEW.cyberaddr_cust = address_cust
                           AND NEW.cyberaddr_address = address_id )
       DO INSTEAD UPDATE elog set elog=false WHERE elog('The selected address does not belong to the selected customer');

CREATE OR REPLACE RULE cyberaddr_custaddress_upd_rule AS
       ON UPDATE TO cyberaddr      
       WHERE NEW.cyberaddr_address IS NOT NULL
             AND NOT EXISTS (SELECT 1
                         FROM address 
                         WHERE NEW.cyberaddr_cust = address_cust
                           AND NEW.cyberaddr_address = address_id )
       DO INSTEAD UPDATE elog set elog=false WHERE elog('The selected address does not belong to the selected customer');

DROP VIEW cyberaddr_list;
CREATE OR REPLACE VIEW cyberaddr_list AS
       SELECT cyberaddr_id, cust_id, 
              cust_last || coalesce(', ' || cust_first,'') as cust_last, 
	      catype_hid,
              COALESCE(address_company || ', ',address_street 
		       || ', ','No Address Selected') 
              	       || COALESCE(address_town,'') AS cyberaddr_address, 
	 case when cyberaddr_url ~ '^[a-z]+:' then '<a href="'|| cyberaddr_url || '">' || cyberaddr_url || '</a>'
              when cyberaddr_url ~ '^[+0-9]' then '<a href="callto:' || cyberaddr_url || '">' || cyberaddr_url || '</a>'
              when cyberaddr_url ~ '^[^ ]+@[^ ]+$' then '<a href="mailto:' || cyberaddr_url || '">' || cyberaddr_url || '</a>'
              when cyberaddr_url ~ '^[^@_ ]+$' then '<a href="http://' || cyberaddr_url || '">' || cyberaddr_url || '</a>'
              else cyberaddr_url
         end as cyberaddr_url,
         '<a href="?search_field001=crm_cust;search_value001=' || cust_id || ';table=crm;action=list">crm</a>' as crm,
         cyberaddr_importance
      FROM cyberaddr LEFT OUTER JOIN address ON (cyberaddr_address = address_id) , cust, catype
       WHERE cyberaddr_cust = cust_id 
             AND  cyberaddr_catype = catype_id
       ORDER BY cust_id ;

COMMENT ON COLUMN cyberaddr_list.crm IS 'Info';

GRANT SELECT ON cyberaddr_list TO GROUP ptpdemo_user;

DROP VIEW cyberaddr_combo;
CREATE OR REPLACE VIEW cyberaddr_combo AS
       SELECT cyberaddr_id AS id,
              (cust_id || ' - '  || cyberaddr_url || ' [' 
	       || catype_hid || ']' ) AS text,
              cust_id as meta_sort
       FROM cyberaddr,catype,cust 
       WHERE cyberaddr_catype = catype_id AND cyberaddr_cust=cust_id
        ORDER BY cust_id,cyberaddr_url;

GRANT SELECT ON cyberaddr_combo TO GROUP ptpdemo_user;


-- -----------------------------------------------------------------------
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
-- Keep timestamps for access to the contacts tables
-- ##############################################################################

CREATE TABLE contact (
  contact_id   SERIAL NOT NULL PRIMARY KEY,
  contact_cust INT4 NOT NULL UNIQUE,
  contact_ts   TIMESTAMP(3) WITH TIME ZONE DEFAULT NOW(),
  contact_user NAME -- who did that change
);

INSERT INTO meta_fields
       VALUES ('contact','contact_ts','widget','readonly');

INSERT INTO meta_tables 
    VALUES ('contact', 'hide','1');  

GRANT SELECT,INSERT,UPDATE,DELETE ON contact TO GROUP ptpdemo_user;
GRANT SELECT,UPDATE ON contact_contact_id_seq TO GROUP ptpdemo_user;

CREATE OR REPLACE FUNCTION contact_cust_stamp () RETURNS trigger
    AS $$
    BEGIN
	IF TG_OP = 'DELETE' THEN
           DELETE FROM contact WHERE contact_cust = OLD.cust_id;
           RETURN OLD;
        END IF;
	IF TG_OP = 'UPDATE' THEN
           UPDATE contact SET contact_ts = NOW(),contact_user = getpgusername() WHERE contact_cust = NEW.cust_id;
        END IF;
	IF TG_OP = 'INSERT' THEN
           INSERT INTO contact (contact_cust,contact_user) VALUES (NEW.cust_id,getpgusername());
        END IF;
	RETURN NEW;
    END; $$
    LANGUAGE plpgsql;

CREATE TRIGGER contact_cust_stamp AFTER INSERT OR UPDATE OR DELETE ON cust
     FOR EACH ROW EXECUTE PROCEDURE contact_cust_stamp();

CREATE OR REPLACE FUNCTION contact_address_stamp () RETURNS trigger
    AS $$
    BEGIN
	IF TG_OP = 'DELETE' THEN
           UPDATE contact SET contact_ts = NOW(),contact_user = getpgusername() WHERE contact_cust = OLD.address_cust;
           RETURN OLD;
        ELSE 
           UPDATE contact SET contact_ts = NOW(),contact_user = getpgusername() WHERE contact_cust = NEW.address_cust;
   	   RETURN NEW;
        END IF;
    END; $$
    LANGUAGE plpgsql;

CREATE TRIGGER contact_address_stamp AFTER INSERT OR UPDATE OR DELETE ON address
     FOR EACH ROW EXECUTE PROCEDURE contact_address_stamp();


CREATE OR REPLACE FUNCTION contact_cyberaddr_stamp () RETURNS trigger
    AS $$
    BEGIN
	IF TG_OP = 'DELETE' THEN
           UPDATE contact SET contact_ts = NOW(),contact_user = getpgusername() WHERE contact_cust = OLD.cyberaddr_cust;
           RETURN OLD;
        ELSE 
           UPDATE contact SET contact_ts = NOW(),contact_user = getpgusername() WHERE contact_cust = NEW.cyberaddr_cust;
           RETURN NEW;
        END IF;
    END; $$
    LANGUAGE plpgsql;

CREATE TRIGGER contact_cyberaddr_stamp AFTER INSERT OR UPDATE OR DELETE ON cyberaddr
     FOR EACH ROW EXECUTE PROCEDURE contact_cyberaddr_stamp();






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

-- ##############################################################################
-- Customer Relationship Type Table
-- ##############################################################################
CREATE TABLE crmt (
   crmt_id      SERIAL NOT NULl PRIMARY KEY,
   crmt_hid     varchar(5) NOT NULL UNIQUE,
   crmt_type    text NOT NULL,
   crmt_desc    text NOT NULL
);

GRANT SELECT,UPDATE ON crmt_crmt_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON crmt TO GROUP ptpdemo_user;

INSERT INTO meta_fields 
       VALUES ('crmt','crmt_desc', 'widget','area');

COMMENT ON TABLE crmt IS 'Z CRM Types';
COMMENT ON COLUMN crmt.crmt_id IS 'ID';
COMMENT ON COLUMN crmt.crmt_hid IS 'HID';
COMMENT ON COLUMN crmt.crmt_type IS 'Type';
COMMENT ON COLUMN crmt.crmt_desc IS 'Description';

DROP VIEW crmt_combo;
CREATE OR REPLACE VIEW crmt_combo AS
       SELECT crmt_id AS id, crmt_hid || ' -- ' 
	      || crmt_type AS text FROM crmt
        ORDER BY crmt_hid,crmt_type ;

GRANT SELECT ON crmt_combo TO GROUP ptpdemo_user;



-- ##############################################################################
-- Company List
-- ##############################################################################
CREATE TABLE company (
   company_id      SERIAL NOT NULl PRIMARY KEY,
   company_hid     varchar(5) NOT NULL UNIQUE,
   company_name    text NOT NULL,
   company_pers    INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user),
   company_cust    INT4 REFERENCES cust,
   company_url     text,
   company_desc    text
);

GRANT SELECT,UPDATE ON company_company_id_seq TO GROUP ptpdemo_user;   
GRANT SELECT,INSERT,UPDATE,DELETE ON company TO GROUP ptpdemo_user;

INSERT INTO meta_fields 
       VALUES ('company','company_desc', 'widget','area');

COMMENT ON TABLE company IS 'C Company';
COMMENT ON COLUMN company.company_id IS 'ID';
COMMENT ON COLUMN company.company_hid IS 'HID';
COMMENT ON COLUMN company.company_name IS 'Company Name';
COMMENT ON COLUMN company.company_pers IS 'Pers';
COMMENT ON COLUMN company.company_cust IS 'Customer';
COMMENT ON COLUMN company.company_url IS 'Web Address';
COMMENT ON COLUMN company.company_desc IS 'Notes';


DROP VIEW company_combo;
CREATE OR REPLACE VIEW company_combo AS
       SELECT company_id AS id, company_hid || ' -- ' 
	      || coalesce(company_url,company_name) AS text FROM company ORDER BY company_hid;

GRANT SELECT ON company_combo TO GROUP ptpdemo_user;

DROP VIEW company_list;
CREATE OR REPLACE VIEW company_list AS
       SELECT 
         company_id,
         company_hid,
         company_name,
         company_url,
         pers_hid as company_pers,
         cust_id || ' ' || cust_last || ', ' || cust_first as company_cust
       FROM company   
            join pers ON (company_pers = pers_id)
            left join cust ON (company_cust = cust_id)
       ORDER BY company_hid DESC;
GRANT SELECT ON company_list to GROUP ptpdemo_user;


-- ##############################################################################
-- Customer Relationship Table
-- ##############################################################################


CREATE TABLE crm (
   crm_id      SERIAL NOT NULl PRIMARY KEY,
   crm_pers    INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user),
   crm_date    DATE NOT NULL DEFAULT CURRENT_DATE,
   crm_cust    INT4 REFERENCES cust,
   crm_company INT4 REFERENCES company,
   crm_cntr    INT4 REFERENCES cntr,
   crm_crmt    INT4 NOT NULL REFERENCES crmt,
   crm_subj    TEXT NOT NULL,
   crm_desc    TEXT
);

GRANT SELECT,UPDATE ON crm_crm_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON crm TO GROUP ptpdemo_user;

INSERT INTO meta_fields 
       VALUES ('crm','crm_desc', 'widget','area');

COMMENT ON TABLE crm IS 'C CRM';
COMMENT ON COLUMN crm.crm_id IS 'ID';
COMMENT ON COLUMN crm.crm_pers IS 'Owner';
COMMENT ON COLUMN crm.crm_date IS 'Action Date';
COMMENT ON COLUMN crm.crm_cust IS 'Customer';
COMMENT ON COLUMN crm.crm_company IS 'Company';
COMMENT ON COLUMN crm.crm_crmt IS 'Type';
COMMENT ON COLUMN crm.crm_cntr IS 'Contract';
COMMENT ON COLUMN crm.crm_subj IS 'Subject';
COMMENT ON COLUMN crm.crm_desc IS 'Notes';

CREATE OR REPLACE RULE crm_ins_rule AS
       ON INSERT TO crm      
       WHERE NEW.crm_cust IS NULL
         AND NEW.crm_cntr IS NULL
         AND NEW.crm_company IS NULL
       DO INSTEAD UPDATE elog set elog=false WHERE elog('At least one of Customer, Contract, Company must be given');

CREATE OR REPLACE RULE crm_upd_rule AS
       ON UPDATE TO crm      
       WHERE NEW.crm_cust IS NULL
         AND NEW.crm_cntr IS NULL
         AND NEW.crm_company IS NULL
       DO INSTEAD UPDATE elog set elog=false WHERE elog('At least one of Customer, Contract, Company must be given');

DROP VIEW crm_list;
CREATE OR REPLACE VIEW crm_list AS
       SELECT 
         crm_id,
         cust_id || ' ' || cust_last || ', ' || cust_first as crm_cust,
         cntr_hid as crm_cntr,
         company_hid || ' - ' || company_name as crm_company,
         crm_date,
         crmt_hid as crm_crmt,
         pers_hid as crm_pers,
         crm_subj
       FROM crm
            join pers ON (crm_pers = pers_id)
            left join cust ON (crm_cust = cust_id)
            left join cntr ON (crm_cntr = cntr_id)
            left join company ON (crm_company = company_id)
            join crmt ON (crm_crmt = crmt_id)
        ORDER BY crm_date DESC;
GRANT SELECT ON crm_list to GROUP ptpdemo_user;



-- ##############################################################################
-- Work Areas
-- ##############################################################################

CREATE TABLE workarea (
   workarea_id     SERIAL NOT NULL PRIMARY KEY,               -- Unique ID
   workarea_hid    VARCHAR(3) NOT NULL UNIQUE,                -- Human Readable Unique ID
   workarea_name   TEXT NOT NULL CHECK (workarea_name != ''), -- Full Name of Workareas
   workarea_pers   INT4 NOT NULL  REFERENCES pers
) WITH OIDS;

GRANT SELECT ON workarea TO GROUP ptpdemo_user;
GRANT SELECT,UPDATE ON workarea_workarea_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON workarea TO GROUP ptpdemo_admin;

COMMENT ON TABLE workarea IS 'Z Workareas';
COMMENT ON COLUMN workarea.workarea_id IS 'ID';
COMMENT ON COLUMN workarea.workarea_hid IS 'Workarea';
COMMENT ON COLUMN workarea.workarea_name IS 'Full Name';
COMMENT ON COLUMN workarea.workarea_pers IS 'Owner';

CREATE OR REPLACE VIEW workarea_list AS
       SELECT workarea_id, workarea_hid, 
	      workarea_name, pers_hid as workarea_pers
       FROM workarea,pers  
       WHERE workarea_pers = pers_id;

GRANT SELECT ON workarea_list TO GROUP ptpdemo_user;

CREATE OR REPLACE VIEW workarea_combo AS
       SELECT workarea_id AS id, workarea_hid || ' -- ' 
	      || workarea_name AS text FROM workarea ORDER BY workarea_hid;

GRANT SELECT ON workarea_combo TO GROUP ptpdemo_user;

-- ############################################################################
-- Contract State
-- ############################################################################

DROP TABLE cntrstate;
DROP SEQUENCE cntrstate_cntrstate_id_seq;

CREATE TABLE cntrstate (
   cntrstate_id     SERIAL NOT NULL PRIMARY KEY,               -- Unique ID
   cntrstate_hid    VARCHAR(5) NOT NULL UNIQUE,                -- Human Readable Unique ID
   cntrstate_name   TEXT NOT NULL CHECK (cntrstate_name != '') -- Full Name of cntrstate
) WITH OIDS;

GRANT SELECT ON cntrstate TO GROUP ptpdemo_user;
GRANT SELECT,UPDATE ON cntrstate_cntrstate_id_seq TO GROUP ptpdemo_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON cntrstate TO GROUP ptpdemo_admin;

COMMENT ON TABLE cntrstate IS 'Z Contract State';
COMMENT ON COLUMN cntrstate.cntrstate_id IS 'ID';
COMMENT ON COLUMN cntrstate.cntrstate_hid IS 'Short Name';
COMMENT ON COLUMN cntrstate.cntrstate_name IS 'Long Name';

DROP VIEW cntrstate_combo;
CREATE OR REPLACE VIEW cntrstate_combo AS
       SELECT cntrstate_id AS id, cntrstate_hid || ' -- ' 
	      || cntrstate_name AS text FROM cntrstate ORDER BY cntrstate_hid;

GRANT SELECT ON cntrstate_combo TO GROUP ptpdemo_user;

-- ############################################################################
-- Contract Type
-- ############################################################################

DROP TABLE cntype;
DROP SEQUENCE cntype_cntype_id_seq;

CREATE TABLE cntype (
   cntype_id     SERIAL NOT NULL PRIMARY KEY,               -- Unique ID
   cntype_hid    VARCHAR(8) NOT NULL UNIQUE,                -- Human Readable Unique ID
   cntype_name   TEXT NOT NULL                              -- Full Name of Contract Type
) WITH OIDS;

GRANT SELECT ON cntype TO GROUP ptpdemo_user;
GRANT SELECT,UPDATE ON cntype_cntype_id_seq TO GROUP ptpdemo_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON cntype TO GROUP ptpdemo_admin;

COMMENT ON TABLE cntype IS 'Z Contract Type';
COMMENT ON COLUMN cntype.cntype_id IS 'ID';
COMMENT ON COLUMN cntype.cntype_hid IS 'Short Name';
COMMENT ON COLUMN cntype.cntype_name IS 'Name';

CREATE OR REPLACE VIEW cntype_combo AS
       SELECT cntype_id AS id, cntype_hid || ' -- ' 
	      || cntype_name AS text FROM cntype ORDER BY cntype_hid;

GRANT SELECT ON cntype_combo TO GROUP ptpdemo_user;

DROP FUNCTION cntype_hid2id(NAME);
CREATE OR REPLACE FUNCTION cntype_hid2id(NAME) returns int4
       AS 'SELECT cntype_id FROM cntype WHERE cntype_hid = $1 ' STABLE 
LANGUAGE 'sql';

-- ####################################################
-- Contracts table. A Project can be part of a Contract
-- ####################################################
CREATE TABLE cntr (
  cntr_id      SERIAL NOT NULL PRIMARY KEY,             			 -- Unique ID
  cntr_hid     VARCHAR(6) NOT NULL UNIQUE CHECK ( cntr_hid ~ '^[-_0-9A-Za-z]+$') -- Unique ID
  cntr_name    TEXT NOT NULL CHECK (cntr_name != ''),   			 -- Contract Name
  cntr_title   TEXT NOT NULL CHECK (cntr_title != ''),  			 -- Contract Title
  cntr_pers    INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user),  -- Contract Owner
  cntr_cust    INT4 NOT NULL REFERENCES cust,           			 -- Contract Customer
  cntr_address INT4 REFERENCES address,           				 -- Contract Billing Address
  cntr_cntrstate INT4 NOT NULL REFERENCES cntrstate, 				 -- Contract State
  cntr_start   DATE NOT NULL DEFAULT CURRENT_DATE,      			 -- Contract Start date
  cntr_offer   DATE DEFAULT CURRENT_DATE CHECK (cntr_offer IS NULL or cntr_offer >= cntr_start),         					 		 -- Contract Offer date
  cntr_order   DATE CHECK (cntr_order IS NULL or cntr_order >= cntr_offer),      -- Contract Order date
  cntr_end     DATE CHECK (cntr_end IS NULL or cntr_end > cntr_start),   	 -- Contract End date
  cntr_likely  BOOLEAN NOT NULL DEFAULT true,     				     -- Is it likely to come?
  cntr_desc    TEXT CHECK (cntr_desc != ''),   					     -- Contract Description
  cntr_hours   FLOAT,								                 -- Total hours offered
  cntr_crnc    INT4 NOT NULL REFERENCES crnc default crnc_hid2id('CHF'),
  cntr_value   DECIMAL(9,2),							             -- Price offered
  cntr_mwst    BOOLEAN NOT NULL DEFAULT true,     				     -- Do they have to pay MWST ?
  cntr_expinc  BOOLEAN NOT NULL DEFAULT false,                                  
  cntr_remhrs  FLOAT CHECK (cntr_remhrs IS NULL OR cntr_remdat IS NOT NULL),                            -- How many hours left  until completed
  cntr_remdat  DATE CHECK (cntr_remdat IS NULL OR cntr_remhrs IS NOT NULL AND cntr_remdat < coalesce(cntr_workend,cntr_end)),                                                             -- When did we guess the hours
  cntr_pool    INT4 NOT NULL REFERENCES pool(pool_id) DEFAULT pool_hid2id('NONE'),-- Contract belongs to pool
  cntr_type    INT4 NOT NULL REFERENCES cntype DEFAULT cntype_hid2id('basic'),
  cntr_workstart DATE CHECK (cntr_workstart >= cntr_start),
  cntr_workend   DATE CHECK (cntr_workend > cntr_workstart AND cntr_workend <= cntr_end),
  cntr_expetype_old INT4 REFERENCES expetype(expetype_id) CHECK (cntr_expetype_old is null OR cntr_start<'2009-01-1'),            -- FIBU account for income before 2009
  cntr_expetype INT4 REFERENCES expetype(expetype_id)                -- FIBU account for income starting with 2009
) WITH OIDS;   

GRANT SELECT,UPDATE ON cntr_cntr_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON cntr TO GROUP ptpdemo_user;

COMMENT ON TABLE  cntr IS 'C Contracts';
COMMENT ON COLUMN cntr.cntr_id        IS 'ID';
COMMENT ON COLUMN cntr.cntr_hid       IS 'Contract ID';
COMMENT ON COLUMN cntr.cntr_name      IS 'Name';
COMMENT ON COLUMN cntr.cntr_title     IS 'Title for Bill';
COMMENT ON COLUMN cntr.cntr_cntrstate IS 'Contract State';
COMMENT ON COLUMN cntr.cntr_pers      IS 'Vendor';
COMMENT ON COLUMN cntr.cntr_cust      IS 'Customer';
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


select SUBSTRING((SELECT (SUBSTRING(MAX(cntr_hid),E'^\\d+'))::INTEGER +10001 
                  FROM cntr WHERE (EXTRACT(YEAR FROM COALESCE('2011-1-1'::date))::INTEGER % 10)::TEXT = SUBSTRING(cntr_hid from 1 for 1)))::TEXT from 2 for 4);

CREATE OR REPLACE FUNCTION cntr_num_gen () RETURNS trigger
    AS $$
    BEGIN
	IF NEW.cntr_hid IS NULL
        THEN
             NEW.cntr_hid := SUBSTRING(
                                ( SELECT MAX(cntr_hid)::INTEGER + 10001 
                                  FROM cntr 
                                  WHERE cntr_hid ~ ('^' || (EXTRACT( YEAR FROM COALESCE(NEW.cntr_workstart,NEW.cntr_start) )::INTEGER % 10)::TEXT || E'\\d\\d\\d$') )::TEXT from 2 for 4);
	END IF;
	RETURN NEW;
    END; $$
    LANGUAGE plpgsql;

drop trigger  cntr_num_gen ON cntr;
CREATE TRIGGER cntr_num_gen BEFORE INSERT ON cntr
     FOR EACH ROW EXECUTE PROCEDURE cntr_num_gen();


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

DROP VIEW cntr_active_combo;
CREATE OR REPLACE VIEW cntr_active_combo AS
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
                nicetrim(cntr_name,35)  || ' [' || cntr_hid || '] ' AS text
                FROM cntr join pool on (cntr_pool=pool_id) join pers on (cntr_pers = pers_id)
                ORDER BY text;


GRANT SELECT ON cntr_active_combo to group ptpdemo_user;

-- contracts still open from yester year
DROP VIEW cntr_open_rep;
CREATE OR REPLACE VIEW cntr_open_rep AS
SELECT '<a href="?action=edit;id=' || cntr_id || ';table=cntr">' || cntr_hid || '</a>' as cntr_hid,
       cntr_name,pers_hid,cntr_start,cntr_end
FROM cntr JOIN pers ON (cntr_pers = pers_id)
WHERE (cntr_end IS NULL OR  cntr_end > CURRENT_DATE) and extract('year' from cntr_start) < extract('year' from current_date)
      and cntr_cntype = 1 and cntr_pool != 9 order by pers_hid,cntr_end;
COMMENT ON VIEW cntr_open_rep IS 'Basic Contracts still open from Yesteryear';
GRANT SELECT ON cntr_open_rep to group ptpdemo_user;

-- ##############################################################################
-- Contract Budget
-- ##############################################################################

CREATE TABLE cntr_bdg (
  cntr_bdg_id      SERIAL NOT NULL PRIMARY KEY,             			 -- Unique ID
  cntr_bdg_cntr    INT4 NOT NULL REFERENCES cntr,                                -- Contract
  cntr_bdg_prod    INT4 REFERENCES prod,           			         -- Product Budget
  cntr_bdg_acti    INT4 REFERENCES acti,                                         -- Activity Budget
  cntr_bdg_pers    INT4 REFERENCES pers,                                         -- person this concerns
  cntr_bdg_hours   float,                                                        -- hours for this budget entry
  cntr_bdg_price   DECIMAL(9,2),                                                 -- budget in the contract currency
  cntr_bdg_note    TEXT,
  CHECK ( NOT (  cntr_bdg_price IS NULL AND cntr_bdg_hours IS NULL )),
  CHECK ( cntr_bdg_prod IS NULL or cntr_bdg_acti IS NULL ),
  CHECK ( NOT ( cntr_bdg_prod IS NULL AND cntr_bdg_acti IS NULL AND cntr_bdg_pers IS NULL))
) WITH OIDS;

COMMENT ON TABLE  cntr_bdg IS 'C Contract  Budget';
COMMENT ON COLUMN cntr_bdg.cntr_bdg_id    IS 'ID';
COMMENT ON COLUMN cntr_bdg.cntr_bdg_cntr  IS 'Contract';
COMMENT ON COLUMN cntr_bdg.cntr_bdg_prod  IS 'Product';
COMMENT ON COLUMN cntr_bdg.cntr_bdg_acti  IS 'Activity';
COMMENT ON COLUMN cntr_bdg.cntr_bdg_pers  IS 'Person';
COMMENT ON COLUMN cntr_bdg.cntr_bdg_hours IS 'Hours';
COMMENT ON COLUMN cntr_bdg.cntr_bdg_price IS 'Price';
COMMENT ON COLUMN cntr_bdg.cntr_bdg_note  IS 'Note';

GRANT SELECT,UPDATE ON cntr_bdg_cntr_bdg_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON cntr_bdg TO GROUP ptpdemo_user;

INSERT INTO meta_fields 
       VALUES ('cntr_bdg','cntr_bdg_note', 'widget','area');

INSERT INTO meta_fields
       VALUES ('cntr_bdg','cntr_bdg_cntr','widget','hidcombo(ref=cntr,combo=cntr_active_combo)');

INSERT INTO meta_fields 
       VALUES ('cntr_bdg','cntr_bdg_acti','widget','idcombo(ref=acti,combo=acti_subscribed_combo)');

CREATE OR REPLACE RULE cntr_bdg_upd_price_rule AS
       ON UPDATE TO cntr_bdg 
       WHERE NEW.cntr_bdg_price IS NOT NULL AND
             COALESCE((SELECT sum(cntr_bdg_price) FROM cntr_bdg WHERE cntr_bdg_cntr = NEW.cntr_bdg_cntr AND cntr_bdg_id != NEW.cntr_bdg_id ),0) + NEW.cntr_bdg_price
             > (SELECT cntr_value FROM cntr where cntr_id = NEW.cntr_bdg_cntr)
       DO INSTEAD UPDATE elog SET elog=false
                  WHERE elog('With this change your price budget would be higher than the available resources in the contract');

CREATE OR REPLACE RULE cntr_bdg_upd_hours_rule AS
       ON UPDATE TO cntr_bdg 
       WHERE NEW.cntr_bdg_hours IS NOT NULL AND
             COALESCE((SELECT sum(cntr_bdg_hours) FROM cntr_bdg WHERE cntr_bdg_cntr = NEW.cntr_bdg_cntr AND cntr_bdg_id != NEW.cntr_bdg_id ),0) + NEW.cntr_bdg_hours
             > (SELECT cntr_hours FROM cntr where cntr_id = NEW.cntr_bdg_cntr)
       DO INSTEAD UPDATE elog SET elog=false
                  WHERE elog('With this change your hour budget would be higher than the available resources in the contract');

CREATE OR REPLACE RULE cntr_bdg_ins_price_rule AS
       ON INSERT TO cntr_bdg 
       WHERE NEW.cntr_bdg_price IS NOT NULL AND
             COALESCE((SELECT sum(cntr_bdg_price) FROM cntr_bdg WHERE cntr_bdg_cntr = NEW.cntr_bdg_cntr ),0)
             > (SELECT cntr_value FROM cntr where cntr_id = NEW.cntr_bdg_cntr)
       DO INSTEAD UPDATE elog SET elog=false
                  WHERE elog('With this entry your price budget would be higher than the available resources in the contract');

CREATE OR REPLACE RULE cntr_bdg_ins_hours_rule AS
       ON INSERT TO cntr_bdg 
       WHERE NEW.cntr_bdg_hours IS NOT NULL AND
             COALESCE((SELECT sum(cntr_bdg_hours) FROM cntr_bdg WHERE cntr_bdg_cntr = NEW.cntr_bdg_cntr ),0)
             > (SELECT cntr_hours FROM cntr where cntr_id = NEW.cntr_bdg_cntr)
       DO INSTEAD UPDATE elog SET elog=false
                  WHERE elog('With this entry your hour budget would be higher than the available resources in the contract');

DROP VIEW cntr_bdg_list;
CREATE OR REPLACE VIEW cntr_bdg_list AS
       SELECT 
         cntr_bdg_id, cntr_hid, cntr_name, pool_hid, pers_hid, 
         CASE 
	   WHEN current_date < cntr_start 
	   THEN false 
	   WHEN current_date > cntr_end 
	   THEN false  
	   ELSE true 
         END AS active,
         ( select pers_hid from pers where pers_id = cntr_bdg_pers ) AS cntr_bdg_pers,
         ( select prod_name from prod where prod_id = cntr_bdg_prod ) AS cntr_bdg_prod,
         ( select acti_name || ' [' || acti_id || ']' from acti where acti_id = cntr_bdg_acti ) AS cntr_bdg_acti,
         cntr_bdg_hours || ' hrs' as cntr_bdg_hours,
         trunc(cntr_bdg_price,0) || ' ' || crnc_hid AS cntr_bdg_price
        FROM
         cntr_bdg, cntr, crnc,pool,pers
        WHERE 
         cntr_bdg_cntr = cntr_id
        AND
         cntr_crnc = crnc_id
        AND
         cntr_pool = pool_id
        AND
         cntr_pers = pers_id;

GRANT SELECT ON cntr_bdg_list TO GROUP ptpdemo_user;

-- ##############################################################################
-- Units table
-- ##############################################################################

CREATE TABLE unit (
   unit_id     SERIAL NOT NULL PRIMARY KEY,               -- Unique ID
   unit_hid    VARCHAR(5) NOT NULL UNIQUE,                   -- Human Readable Unique ID
   unit_name   TEXT NOT NULL CHECK (unit_name != '')      -- Full Name of Unit
) WITH OIDS;

GRANT SELECT,UPDATE ON unit_unit_id_seq TO GROUP ptpdemo_admin;
GRANT SELECT ON unit TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON unit TO GROUP ptpdemo_admin;

COMMENT ON TABLE unit IS 'Z Units';
COMMENT ON COLUMN unit.unit_id IS 'ID';
COMMENT ON COLUMN unit.unit_hid IS 'Unit';
COMMENT ON COLUMN unit.unit_name IS 'Full Name';

CREATE OR REPLACE VIEW unit_combo AS
       SELECT unit_id AS id, unit_hid || '--' || unit_name AS text FROM unit ORDER BY unit_hid,unit_name;

GRANT SELECT ON unit_combo TO GROUP ptpdemo_user;

-- ##############################################################################
-- Products table.
-- ##############################################################################

CREATE TABLE prod (
   prod_id       SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
   prod_name     TEXT NOT NULL CHECK (prod_name != ''),   -- Prodect Name
   prod_pers     INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user), -- Product Manager
   prod_start    DATE NOT NULL DEFAULT CURRENT_DATE,      -- Prodect Start date
   prod_end      DATE CHECK (prod_end is NULL or prod_end > prod_start),   -- Prodect End date
   prod_unit     INT4 NOT NULL REFERENCES unit, -- Was ist die Kenngroesse fuer dieses Produkt
   prod_desc     TEXT NOT NULL CHECK (prod_desc != ''),   -- Prodect Description
   prod_workarea INT4 NOT NULL REFERENCES workarea,
   prod_units    TEXT                                     -- Description of what "units" of this products are (for cntrprod)
) WITH OIDS;   


GRANT SELECT,UPDATE ON prod_prod_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON prod TO GROUP ptpdemo_user;

COMMENT ON TABLE prod IS 'B Products';
COMMENT ON COLUMN prod.prod_id IS 'ID';
COMMENT ON COLUMN prod.prod_name IS 'Name';
COMMENT ON COLUMN prod.prod_pers IS 'Owner';
COMMENT ON COLUMN prod.prod_start IS 'Start Date';
COMMENT ON COLUMN prod.prod_end IS 'End Date';
COMMENT ON COLUMN prod.prod_unit IS 'Unit';
COMMENT ON COLUMN prod.prod_desc IS 'Description';
COMMENT ON COLUMN prod.prod_workarea IS 'Work Area';
COMMENT ON COLUMN prod.prod_units IS 'Definition of "Units"';

INSERT INTO meta_fields VALUES ('prod','prod_desc', 'widget','area');

CREATE OR REPLACE VIEW prod_list AS
       SELECT prod_id, workarea_hid,  prod_name, pers_hid AS prod_pers, 
              prod_start, prod_end,
              CASE 
		WHEN current_date < prod_start 
	        THEN false 
	        WHEN current_date > prod_end 
	        THEN false  
                ELSE true 
              END as active,
	      prod_units
       FROM pers, workarea, prod
       WHERE  prod_pers=pers_id
              AND prod_workarea = workarea_id;

GRANT SELECT ON prod_list to group ptpdemo_user;
COMMENT ON COLUMN prod_list.active IS 'Active';

-- alternative combo for cntrprod
CREATE OR REPLACE VIEW prod_cntrprod_combo AS
        SELECT prod_id AS id,
                CASE WHEN current_date < prod_start OR current_date > prod_end   THEN '~ '
                ELSE '' END ||
                workarea_hid || ' ' ||  prod_name || '  [' || prod_id || ']' ||
		CASE WHEN prod_units IS NULL THEN '' ELSE ', ' || prod_units END
		as text
               FROM workarea, prod
               WHERE prod_workarea=workarea_id
               ORDER BY text;
GRANT SELECT ON prod_cntrprod_combo to group ptpdemo_user;

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


CREATE OR REPLACE FUNCTION acti_check () RETURNS trigger
    AS $$
    BEGIN
	IF EXISTS ( SELECT prod_id 
		    FROM prod 
		    WHERE ( NEW.acti_start < prod_start OR NEW.acti_end > prod_end OR 
			    (NEW.acti_end IS NULL  and prod_end IS NOT NULL )) AND 
			    prod_id = NEW.acti_prod ) 
        THEN
            RAISE EXCEPTION 'The selected Product is not valid for the entire date range specified in the activity. This includes activities without end for products with end.';
	END IF;
	RETURN NEW;
    END; $$
    LANGUAGE plpgsql;

CREATE TRIGGER acti_check BEFORE INSERT OR UPDATE ON acti
     FOR EACH ROW EXECUTE PROCEDURE acti_check();

-- ##############################################################################
-- Rules for updating tables pointing to activities
-- ##############################################################################

CREATE OR REPLACE RULE prod_daterange_rule AS 
       ON UPDATE TO prod
       WHERE EXISTS (SELECT acti_id
              FROM acti WHERE acti_prod = NEW.prod_id 
                          AND ( acti_start < NEW.prod_start 
                             OR acti_end > NEW.prod_end
			     OR ( acti_end is NULL and NEW.prod_end is NOT NULL )))
       DO INSTEAD UPDATE elog set elog=false where elog('There would be activities, pointing to this product outside the active range. Including Activities without end date.');


-- ##############################################################################
-- Fixed Rates for selected activities
-- ##############################################################################
DROP TABLE acti_rate;

CREATE TABLE acti_rate (
   acti_rate_id     SERIAL NOT NULL PRIMARY KEY,        -- Unique ID
   acti_rate_pers   INT4 NOT NULL REFERENCES pers,      -- Who gets this rate
   acti_rate_acti   INT4 NOT NULL REFERENCES acti,      -- For which activity
   acti_rate_start  DATE NOT NULL DEFAULT CURRENT_DATE, -- The Rate is valid from this date
   acti_rate_rate   DECIMAL(9,2) NOT NULL,              -- Hourly Rate
   acti_rate_note   TEXT                                -- Notes Regarding the Rate
) WITH OIDS;   

GRANT SELECT,UPDATE ON acti_rate_acti_rate_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON acti_rate TO GROUP ptpdemo_user;

COMMENT ON TABLE acti_rate IS 'Z Activity Rates';
COMMENT ON COLUMN acti_rate.acti_rate_id IS 'ID';
COMMENT ON COLUMN acti_rate.acti_rate_pers IS 'Worker';
COMMENT ON COLUMN acti_rate.acti_rate_acti IS 'Activity';
COMMENT ON COLUMN acti_rate.acti_rate_start IS 'Start Date';
COMMENT ON COLUMN acti_rate.acti_rate_rate IS 'Rate/h';
COMMENT ON COLUMN acti_rate.acti_rate_note IS 'Note';

INSERT INTO meta_fields VALUES ('acti_rate','acti_rate_note', 'widget','area');

DROP VIEW acti_rate_list;
CREATE OR REPLACE VIEW acti_rate_list AS
    SELECT 
        acti_rate_id,  pers_hid,acti_id, acti_name, acti_rate_start,
	acti_rate_rate
    FROM
        acti,acti_rate,pers
    WHERE 
          acti_rate_pers = pers_id
      AND acti_rate_acti = acti_id;

GRANT SELECT ON acti_rate_list TO GROUP ptpdemo_user;

-- ##############################################################################
-- Who can work on which Function/Project related activities
-- ##############################################################################

CREATE TABLE  prodpers (
   prodpers_id    SERIAL NOT NULL PRIMARY KEY,  -- Unique ID
   prodpers_pers  INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user),
   prodpers_prod  INT4 NOT NULL REFERENCES prod,
   UNIQUE(prodpers_pers,prodpers_prod)
) WITH OIDS;

COMMENT ON TABLE prodpers IS 'B Product Subscriptions';
COMMENT ON COLUMN prodpers.prodpers_id IS  'ID';
COMMENT ON COLUMN prodpers.prodpers_pers IS 'Pers';
COMMENT ON COLUMN prodpers.prodpers_prod IS 'Product';

-- no updating for the prodpers list
GRANT SELECT,UPDATE,DELETE,INSERT ON prodpers TO GROUP ptpdemo_user;
GRANT SELECT,UPDATE ON prodpers_prodpers_id_seq TO GROUP ptpdemo_user;

INSERT INTO meta_fields 
       VALUES ('prodpers','prodpers_prod','copy',   '1');
INSERT INTO meta_fields 
       VALUES ('prodpers','prodpers_pers','copy',   '1');


CREATE OR REPLACE RULE prodpers_ins_rule AS 
       ON INSERT TO prodpers
       WHERE (new.prodpers_pers != pers_hid2id(current_user)) 
	     AND not ingroup('ptpdemo_admin')
             AND not exists (select * from prod where new.prodpers_prod = prod_id and prod_pers = pers_hid2id(current_user))
       DO INSTEAD UPDATE elog set elog=false where elog('Either add entries for yourself or for Functions/Projects you are responsible for');

CREATE OR REPLACE RULE prodpers_upd_rule AS 
       ON UPDATE TO prodpers
       DO INSTEAD UPDATE elog set elog=false where elog('Either add or delete entries on this list, do not change them!');

CREATE OR REPLACE RULE prodpers_del_rule AS 
       ON DELETE TO prodpers
       WHERE (old.prodpers_pers != pers_hid2id(current_user)) 
             AND not ingroup('ptpdemo_admin')
             AND not exists (select * from prod where old.prodpers_prod = prod_id and prod_pers = pers_hid2id(current_user))
       DO INSTEAD UPDATE elog set elog=false where elog('You can only delete your own entries');

CREATE OR REPLACE VIEW prodpers_list AS
       SELECT prodpers_id, 
              workarea_hid, 
              CASE 
                WHEN current_date < prod_start OR current_date > prod_end THEN '~ ' 
                ELSE '' 
              END || prod_name || ' [' || prod_id || ']' as prodpers_prod, pers_hid
       FROM  prodpers,pers,prod,workarea
       WHERE prodpers_pers = pers_id and 
             prodpers_prod = prod_id and
             ( pers_hid = CURRENT_USER OR exists (select * from prod where prodpers_prod = prod_id and prod_pers = pers_hid2id(current_user)) ) and
             prod_workarea = workarea_id
       UNION 
       SELECT NULL as prodpers_id,
              workarea_hid,
	      prod_name || ' [' || prod_id || ']' as prodpers_prod, pers_hid
       FROM prod,workarea,pers
       WHERE pers_hid = CURRENT_USER
	AND  prod_pers = pers_id
        AND  CASE 
                WHEN current_date < prod_start OR current_date > prod_end THEN false
                ELSE true
             END
        AND  prod_workarea = workarea_id
       ORDER by workarea_hid,prodpers_prod,pers_hid,prodpers_id;


COMMENT ON COLUMN prodpers_list.pers_hid IS  'Pers';

GRANT SELECT ON prodpers_list TO GROUP ptpdemo_user;

-- can have the como only once i know about the prodpers

CREATE OR REPLACE VIEW prod_combo AS
        SELECT prod_id AS id,
                CASE WHEN current_date < prod_start OR current_date > prod_end   THEN '~ '    
	             WHEN EXISTS (select pers_id
                                    from pers 
                                   where pers_hid = current_user
                                     AND pers_id = prod_pers
                                  )  THEN '+ ' 
	             WHEN EXISTS (select prodpers_id 
                                    from prodpers,pers 
                                   where pers_id = prodpers_pers 
                                           AND pers_hid = current_user
                                           AND prodpers_prod = prod_id
                                  )  THEN ': ' 
                     ELSE '? ' END ||   
               workarea_hid || ' ' ||  prod_name || ' [' || prod_id || ']' as text
               FROM workarea, prod
               WHERE prod_workarea=workarea_id
               ORDER BY text;


GRANT SELECT ON prod_combo to group ptpdemo_user;

-- ##############################################################################
-- Contract to Products selection
-- ##############################################################################

CREATE TABLE cntrprod (
   cntrprod_id     SERIAL NOT NULL PRIMARY KEY,        -- Unique ID
   cntrprod_cntr  INT4 NOT NULL REFERENCES cntr,     -- Which cntrract ?
   cntrprod_prod   INT4 NOT NULL REFERENCES prod,      -- Which project ?
   cntrprod_unts   decimal(9,2) NOT NULL,           
   UNIQUE (cntrprod_cntr,cntrprod_prod)) WITH OIDS;

CREATE INDEX cntrprod_cntr_key ON cntrprod (cntrprod_cntr);
CREATE INDEX cntrprod_prod_key ON cntrprod (cntrprod_prod);

COMMENT ON TABLE cntrprod IS 'Z Product selection for Contracts';
COMMENT ON COLUMN cntrprod.cntrprod_id IS 'CntrID';
COMMENT ON COLUMN cntrprod.cntrprod_cntr IS 'Contract';
COMMENT ON COLUMN cntrprod.cntrprod_prod IS 'Product';
COMMENT ON COLUMN cntrprod.cntrprod_unts IS 'Numer of Units';

GRANT SELECT,UPDATE ON cntrprod_cntrprod_id_seq TO GROUP ptpdemo_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON cntrprod TO GROUP ptpdemo_user;

DELETE FROM meta_fields WHERE meta_fields_table = 'cntrprod';
INSERT INTO meta_fields VALUES ('cntrprod','cntrprod_cntr','copy',   '1');
INSERT INTO meta_fields VALUES ('cntrprod','cntrprod_prod','copy',   '1');
INSERT INTO meta_fields VALUES ('cntrprod','cntrprod_prod','widget', 'idcombo(ref=prod,combo=prod_cntrprod_combo)');

CREATE OR REPLACE VIEW cntrprod_list AS
       SELECT cntrprod_id, cntr_hid, cntr_name,
	      workarea_hid, prod_name, cntrprod_unts
	FROM cntrprod, workarea, prod, cntr
	WHERE cntrprod_cntr=cntr_id 
          AND cntrprod_prod=prod_id
	  AND prod_workarea=workarea_id;

GRANT SELECT ON cntrprod_list TO GROUP ptpdemo_user;

INSERT INTO meta_fields VALUES ('cntrprod_list', 'cntr_id','reference','cntr');

-- INSERT INTO meta_fields
--       VALUES ('cntrprod_list', 'cntr_id','reference','cntr');
-- INSERT INTO meta_fields
--        VALUES ('cntrprod_list', 'prod_id','reference','prod');

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

CREATE OR REPLACE VIEW acti_subscribed_combo AS
        SELECT acti_id AS id,
	  CASE  WHEN current_date < acti_start
                     OR current_date > acti_end THEN '~ '
                WHEN prod_pers = pers_id
	             OR  EXISTS (select * 
                                  from prodpers
                                  where prodpers_prod = prod_id 
	                          AND prodpers_pers = pers_id
 	                          AND prodpers_prod = acti_prod ) 
                THEN ''
                ELSE '| ' 
            END ||
               workarea_hid || ' ' ||  acti_name || ' [' || acti_id || ']' as text
	FROM workarea, acti, pers, prod
	WHERE pers_hid = CURRENT_USER
          AND acti_prod = prod_id
          AND prod_workarea=workarea_id order by text ;

GRANT SELECT ON acti_subscribed_combo to group ptpdemo_user;



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
-- WorkType table. List of all types of work we do including prices
-- ##############################################################################

CREATE TABLE woty_cost (
        woty_cost_id SERIAL NOT NULL PRIMARY KEY,                       -- Unique ID
        woty_cost_woty INT4 REFERENCES woty NOT NULL,                            -- Which Work Type
        woty_cost_start DATE NOT NULL,                                           -- From when is this cost valid
        woty_cost_pers INT4 REFERENCES pers,                            -- which worker does this apply to
        woty_cost_rate NUMERIC(9,2) NOT NULL                             -- Cost Per Unit
);

GRANT SELECT,UPDATE ON woty_cost_woty_cost_id_seq TO GROUP ptpdemo_admin;
GRANT SELECT ON woty_cost TO GROUP ptpdemo_user;     
GRANT SELECT,INSERT,UPDATE,DELETE ON woty_cost TO GROUP ptpdemo_admin;
        
COMMENT ON TABLE woty_cost IS 'Z Work Type Rates';
COMMENT ON COLUMN woty_cost.woty_cost_id IS 'ID';
COMMENT ON COLUMN woty_cost.woty_cost_woty IS 'Worktype';
COMMENT ON COLUMN woty_cost.woty_cost_start IS 'Valid from';
COMMENT ON COLUMN woty_cost.woty_cost_pers IS 'Worker';
COMMENT ON COLUMN woty_cost.woty_cost_rate IS 'Cost per Unit';

DROP VIEW woty_cost_list;
CREATE OR REPLACE VIEW woty_cost_list AS
       SELECT woty_cost_id, woty_hid, pers_hid, woty_cost_start, woty_cost_rate, 'per ' || unit_hid as unit_hid
       FROM woty_cost JOIN woty ON (woty_cost_woty = woty_id ) 
                      JOIN unit ON (woty_unit = unit_id )
                LEFT JOIN pers  ON (woty_cost_pers = pers_id )

GRANT SELECT ON woty_cost_list TO GROUP ptpdemo_user;


-- ##############################################################################
-- Invoices we sent
-- ##############################################################################

DROP TABLE invoice;
DROP SEQUENCE invoice_invoice_id_seq;
CREATE TABLE invoice (
  invoice_id       SERIAL NOT NULL PRIMARY KEY,      -- unique ID
  invoice_cntr     INT4 NOT NULL REFERENCES cntr,    -- contract
  invoice_due      DATE,               		     -- date when expected
  invoice_sent     DATE,               		     -- date when sent
  invoice_paid     DATE,               		     -- date when paid
  invoice_expenses numeric(9,2),                     -- how much for expenses [chf]
  invoice_expenses_ovr numeric(9,2),                 -- expenses amount override
  invoice_mwst     numeric(9,2),                     -- mwst to be added to the bill [NAT]
  invoice_paid_chf numeric(9,2),                     -- how much did the people actually pay
  invoice_work_nat numeric(9,2),                     -- work amount printed on invoice
  invoice_expenses_nat numeric(9,2),                 -- expenses amount printed on invoice
  invoice_address  INT4 REFERENCES address,          -- if the bill should be sent to some other address, pick here
  invoice_desc     TEXT CHECK ( invoice_desc != ''), -- background info
  invoice_remark   TEXT,                             -- remark to be printed on the invoice
  invoice_acct     INT4 REFERENCES acct,             -- which account does this get paid in
  invoice_mod_date DATE,			     -- last change
  invoice_mod_user NAME				     -- by whom
) WITH OIDS;

CREATE INDEX invoice_cntr_idx on invoice(invoice_cntr);


GRANT SELECT ON invoice TO GROUP ptpdemo_user;
GRANT SELECT,UPDATE ON invoice_invoice_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON invoice TO GROUP ptpdemo_user;

COMMENT ON TABLE  invoice                  IS 'C Invoices';
COMMENT ON COLUMN invoice.invoice_id       IS 'ID';
COMMENT ON COLUMN invoice.invoice_cntr     IS 'Contract ID';
COMMENT ON COLUMN invoice.invoice_due      IS 'Due Date';
COMMENT ON COLUMN invoice.invoice_sent     IS 'Send Date';
COMMENT ON COLUMN invoice.invoice_paid     IS 'Pay Date';
COMMENT ON COLUMN invoice.invoice_work_nat IS 'Work [Native]';
COMMENT ON COLUMN invoice.invoice_mwst     IS 'MWSt';
COMMENT ON COLUMN invoice.invoice_expenses_ovr IS 'Expenses override [CHF]';
COMMENT ON COLUMN invoice.invoice_expenses_nat IS 'Expenses [Native]';
COMMENT ON COLUMN invoice.invoice_paid_chf IS 'Amount Paid [CHF]';
COMMENT ON COLUMN invoice.invoice_expenses IS 'Expenses [CHF]';
COMMENT ON COLUMN invoice.invoice_desc     IS 'Internal Note';
COMMENT ON COLUMN invoice.invoice_remark   IS 'Print this on Invoice';
COMMENT ON COLUMN invoice.invoice_acct     IS 'Account';
COMMENT ON COLUMN invoice.invoice_address  IS 'Address override';
COMMENT ON COLUMN invoice.invoice_remark   IS 'Print this on Invoice';

COMMENT ON COLUMN invoice.invoice_mod_date IS 'Letzte Änderung am';
COMMENT ON COLUMN invoice.invoice_mod_user IS 'Letzte Änderung von';

INSERT INTO meta_fields 
       VALUES ('invoice','invoice_due','copy','1');

INSERT INTO meta_fields 
       VALUES ('invoice','invoice_sent','copy','1');

INSERT INTO meta_fields 
       VALUES ('invoice','invoice_paid','copy','1');

INSERT INTO meta_fields 
       VALUES ('invoice','invoice_cntr','copy','1');

INSERT INTO meta_fields VALUES ('invoice','invoice_desc', 'widget','area');
INSERT INTO meta_fields VALUES ('invoice','invoice_remark', 'widget','area');

DROP VIEW invoice_list;
CREATE OR REPLACE VIEW invoice_list AS
      SELECT invoice_id,  
             cntr_hid || ' - ' || cntr_name as contract,
	     pool_hid || ':' || pers_sign as owner,
             invoice_due,invoice_sent,invoice_paid,
	     cntr_value,
	     ROUND(invoice_work_nat::numeric,2) as invoice_work_nat, 
	     ROUND(invoice_expenses_ovr::numeric,2) as invoice_expenses_ovr,
	     ROUND(invoice_expenses_nat::numeric,2) as invoice_expenses_nat,
	     crnc_hid,
	     ROUND(invoice_paid_chf::numeric,2) as invoice_paid_chf,
	     ROUND(invoice_mwst::numeric,2) as invoice_mwst,
         expetype_hid || ': ' || expetype_name as fibu
         FROM invoice JOIN cntr ON invoice_cntr=cntr_id
                      JOIN pool ON cntr_pool=pool_id
                      JOIN pers ON cntr_pers=pers_id
                      JOIN crnc ON cntr_crnc=crnc_id
                      LEFT JOIN expetype on (cntr_expetype=expetype_id)
      -- FROM invoice,cntr, pool, pers, crnc, expetype
      -- WHERE  invoice_cntr = cntr_id
  	  --    AND cntr_crnc    = crnc_id
      --    AND cntr_pool    = pool_id
      --    AND cntr_pers    = pers_id
      --    AND cntr_expetype = expetype_id
      ORDER BY contract;

GRANT SELECT ON invoice_list TO GROUP ptpdemo_user;
COMMENT ON COLUMN invoice_list.owner IS 'Owner';
COMMENT ON COLUMN invoice_list.contract IS 'Contract';
COMMENT ON COLUMN invoice_list.crnc_hid IS 'Currency [Native]';
COMMENT ON COLUMN invoice_list.fibu IS 'Cntr FIBU account';

DROP FUNCTION invoice_stamp();
CREATE OR REPLACE FUNCTION invoice_stamp () RETURNS TRIGGER AS $$
    BEGIN
        -- Remember who changed the entry and when
        NEW.invoice_mod_date := CURRENT_DATE;
	NEW.invoice_mod_user := getpgusername();
        RETURN NEW;
    END;
$$ LANGUAGE 'plpgsql';

--
DROP TRIGGER invoice_stamp ON invoice;
CREATE TRIGGER invoice_stamp BEFORE INSERT OR UPDATE ON invoice
    FOR EACH ROW EXECUTE PROCEDURE invoice_stamp();

INSERT INTO "meta_fields" 
       VALUES ('invoice','invoice_mod_date','widget','readonly');
INSERT INTO "meta_fields" 
       VALUES ('invoice','invoice_mod_user','widget','readonly');
INSERT INTO "meta_fields" 
       VALUES ('invoice','invoice_expenses_nat','widget','readonly');
INSERT INTO "meta_fields" 
       VALUES ('invoice','invoice_expenses','widget','readonly');
INSERT INTO "meta_fields" 
       VALUES ('invoice','invoice_mwst','widget','readonly');


-- this function runs as ptpdemo and as such is allowd to modify any
-- entry in the wolo table which normal users would not be
CREATE OR REPLACE FUNCTION null_eq(a anyelement, b anyelement) RETURNS boolean AS $$
    BEGIN
    if (a is null and b is null) OR a=b THEN
        return true;
    ELSE 
        return false;
    END IF;
    END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

CREATE OR REPLACE FUNCTION round_05(a float) RETURNS float AS $$
    BEGIN
       RETURN round(a*20)/20;
    END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

CREATE OR REPLACE FUNCTION invoice_check () RETURNS trigger AS $$
DECLARE
    old_path TEXT;
    expense_chf FLOAT;
BEGIN
    -- Save old search_path; notice we must qualify current_setting
    -- to ensure we invoke the right function
    old_path := pg_catalog.current_setting('search_path');

    -- Set a secure search_path: trusted schemas, then 'pg_temp'.
    -- We set is_local = true so that the old value will be restored
    -- in event of an error before we reach the function end.
    PERFORM pg_catalog.set_config('search_path', 'public', true);

    -- make sure we do not overcharge    
        
--    IF (SELECT SUM(invoice_work_nat) FROM invoice WHERE invoice_cntr = NEW.invoice_cntr AND invoice_id <> NEW.invoice_id )
--        > (SELECT cntr_value FROM cntr WHERE cntr_id = NEW.invoice_cntr)
--    THEN
--        RAISE EXCEPTION 'This change would cause the total billed amount to be larger than the amount in the contract (%)',
--        (select cntr_hid from cntr where cntr_id = NEW.invoice_cntr);
--    END IF;


    IF NEW.invoice_paid IS NOT NULL AND NEW.invoice_paid_chf IS NULL OR NEW.invoice_paid IS NULL AND NEW.invoice_paid_chf IS NOT NULL  THEN
         RAISE EXCEPTION 'Enter both: the date the invoice was paid AND the total CHF amount you received including MWSt. InvoicID %',
            NEW.invoice_id;
    END IF;

    IF NEW.invoice_due IS NULL AND NEW.invoice_sent IS NOT NULL THEN
         RAISE EXCEPTION 'Every invoice sent should have a due date ! Invoice %',
            NEW.invoice_id;
    END IF;

    IF NEW.invoice_paid < NEW.invoice_sent THEN
         RAISE EXCEPTION 'Paid date cannot be before send Date ! Invoice %',
            NEW.invoice_id;
    END IF;

    IF TG_OP = 'INSERT' THEN
        IF NEW.invoice_expenses is NOT NULL THEN
            RAISE EXCEPTION 'The expense field gets calculated when you set the sent date. Do not edit it (Invoice %)', NEW.invoice_id;
        END IF;

        IF NEW.invoice_expenses_nat is NOT NULL THEN
            RAISE EXCEPTION 'The expense_nat field gets calculated when you set the sent date. Do not edit it (Invoice %)', NEW.invoice_id;
        END IF;

        IF NEW.invoice_mwst is NOT NULL THEN
            RAISE EXCEPTION 'The mwst field gets calculated when you set the sent date. Do not edit it (Invoice %)', NEW.invoice_id;
        END IF;
        -- shortcirquit here when invoice has no sent date
        IF NEW.invoice_sent is NULL THEN
           PERFORM pg_catalog.set_config('search_path', old_path, true);
           RETURN NEW;
        END IF;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        IF not null_eq(NEW.invoice_expenses,OLD.invoice_expenses) THEN
            RAISE EXCEPTION 'The expense field gets calculated when you set the sent date. Do not edit it (Invoice %)', NEW.invoice_id;
        END IF;

        IF not null_eq(NEW.invoice_expenses_nat,OLD.invoice_expenses_nat) THEN
            RAISE EXCEPTION 'The expense_nat field gets calculated when you set the sent date. Do not edit it (Invoice %)', NEW.invoice_id;
        END IF;

        IF not null_eq(NEW.invoice_mwst,OLD.invoice_mwst) THEN
            RAISE EXCEPTION 'The mwst field gets calculated when you set the sent date. Do not edit it (Invoice % >%< != >%< )', NEW.invoice_id,NEW.invoice_mwst,OLD.invoice_mwst;
        END IF;

        IF OLD.invoice_sent IS NOT NULL AND 
           ( not null_eq(NEW.invoice_work_nat,OLD.invoice_work_nat) 
             OR not null_eq(NEW.invoice_remark,OLD.invoice_remark) )
        THEN
               RAISE EXCEPTION 'Invoice % has been sent already. Do not change its value!', NEW.invoice_id;
        END IF;

        -- clear old invoice since sent got deleted
        IF NEW.invoice_sent IS NULL AND OLD.invoice_sent IS NOT NULL THEN
           UPDATE wolo SET wolo_invoice = NULL WHERE wolo_invoice = NEW.invoice_id;
           NEW.invoice_expenses := NULL;
           NEW.invoice_expenses_nat := NULL;
           NEW.invoice_mwst := NULL;
        END IF;

        -- no new invoice ... we are done
        IF NEW.invoice_sent = OLD.invoice_sent THEN
           PERFORM pg_catalog.set_config('search_path', old_path, true);
           RETURN NEW;
        END IF;
    END IF;

    -- if invoice_sent is not null but the same as before, we are already gone! see right above
    IF NEW.invoice_sent IS NOT NULL THEN
        -- remove old entries for this bill
        UPDATE wolo SET wolo_invoice = NULL WHERE wolo_invoice = NEW.invoice_id;
        expense_chf := round_05((SELECT SUM(a.wolo_chf) FROM wolo_expense_view as a join wolo as b on (a.wolo_id = b.wolo_id) 
                                                      WHERE a.wolo_cntr = NEW.invoice_cntr AND a.wolo_invoice IS NULL and b.wolo_date <= NEW.invoice_sent));
        -- only expense over 10 CHF get included
        IF expense_chf > 10 THEN
            UPDATE wolo SET wolo_invoice = NEW.invoice_id WHERE wolo_id IN ( SELECT a.wolo_id FROM wolo_expense_view as a join wolo as b on (a.wolo_id = b.wolo_id) 
                                                                                            WHERE a.wolo_cntr = NEW.invoice_cntr AND a.wolo_invoice IS NULL and b.wolo_date <= NEW.invoice_sent );
            NEW.invoice_expenses := expense_chf;
            NEW.invoice_expenses_nat := round_05(expense_chf * ( SELECT crnc_rate FROM crnc,cntr WHERE crnc_id = cntr_crnc AND cntr_id = NEW.invoice_cntr ));
        ELSE
            NEW.invoice_expenses := 0;
            NEW.invoice_expenses_nat := 0;
        END IF;

        IF (SELECT cntr_mwst FROM cntr WHERE cntr_id = NEW.invoice_cntr) THEN
             IF (SELECT cntr_expinc FROM cntr WHERE cntr_id = NEW.invoice_cntr) THEN
                 NEW.invoice_mwst := round_05(( coalesce(NEW.invoice_work_nat,0) ) * 0.076);
             ELSE
                 NEW.invoice_mwst := round_05(( NEW.invoice_expenses_nat + coalesce(NEW.invoice_work_nat,0) ) * 0.076);
             END IF;
        ELSE
             NEW.invoice_mwst := 0;
        END IF;

    END IF;
    -- Restore caller's search_path
    PERFORM pg_catalog.set_config('search_path', old_path, true);
    RETURN NEW;
END; 
$$
LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER invoice_check ON invoice;
CREATE TRIGGER invoice_check BEFORE INSERT OR UPDATE ON invoice
     FOR EACH ROW EXECUTE PROCEDURE invoice_check();


CREATE OR REPLACE FUNCTION invoice_del_check () RETURNS trigger AS $$
BEGIN
    IF OLD.invoice_sent IS NOT NULL THEN
        RAISE EXCEPTION 'Invoice % has been sent already. Do not delete it!', OLD.invoice_id;
    END IF;
    RETURN OLD;
END; 
$$ 
LANGUAGE plpgsql;

DROP TRIGGER invoice_del_check ON invoice;
CREATE TRIGGER invoice_del_check BEFORE DELETE ON invoice
     FOR EACH ROW EXECUTE PROCEDURE invoice_del_check();


CREATE OR REPLACE VIEW invoice_data_rep AS
SELECT cntr_title,
       CASE WHEN invoice_address IS NOT NULL THEN ia.address_company ELSE  ca.address_company END as address_company,
       CASE WHEN invoice_address IS NOT NULL THEN ia.address_street ELSE  ca.address_street END as address_street,
       CASE WHEN invoice_address IS NOT NULL THEN ia.address_zip ELSE  ca.address_zip END as address_zip,
       CASE WHEN invoice_address IS NOT NULL THEN ia.address_town ELSE  ca.address_town END as address_town,
       CASE WHEN invoice_address IS NOT NULL THEN ia.address_country ELSE  ca.address_country END as address_country,
       CASE WHEN invoice_address IS NOT NULL THEN ic.cust_first ELSE  cc.cust_first END as cust_first,
       CASE WHEN invoice_address IS NOT NULL THEN ic.cust_last ELSE  cc.cust_last END as cust_last,
       CASE WHEN invoice_address IS NOT NULL THEN ic.cust_title ELSE  cc.cust_title END as cust_title,
       CASE WHEN invoice_address IS NOT NULL THEN ic.cust_gender ELSE  cc.cust_gender END as cust_gender,
       invoice_remark,
       invoice_sent,
       crnc_hid,
       invoice_work_nat, 
       invoice_expenses_nat,
       cntr_mwst, 
       crnc_invc, 
       cntr_hid,
       CASE WHEN invoice_address IS NOT NULL THEN ic.cust_id ELSE  cc.cust_id END as cust_id,
       invoice_id,
       invoice_mwst,
       get_mwst(1,invoice_sent) as mwst_rate 
FROM invoice
     JOIN cntr ON invoice_cntr = cntr_id
     JOIN cust AS cc ON cntr_cust = cc.cust_id
     JOIN crnc ON cntr_crnc = crnc_id
     LEFT JOIN address AS ca ON cntr_address = ca.address_id
     LEFT JOIN address AS ia ON invoice_address = ia.address_id
     LEFT JOIN cust AS ic ON ia.address_cust = ic.cust_id;

GRANT SELECT ON invoice_data_rep TO GROUP ptpdemo_user;
INSERT INTO meta_tables VALUES ('invoice_data_rep', 'hide','1');


DROP VIEW invoice_next_month_rep;
CREATE VIEW invoice_next_month_rep AS
      SELECT 
	'<a target=_new href=?action=edit&table=invoice&id=' || 
	invoice_id || '>Edit</a>' AS Edit,
        invoice_id,
        cntr_hid || ' - ' || cntr_name AS contract,
	pool_hid || ':' || pers_sign as owner,
        invoice_due,invoice_sent,invoice_paid,
        ROUND(invoice_work_nat::numeric,2) as invoice_work_nat, crnc_hid
      FROM invoice, cntr, pool, pers, crnc
      WHERE  
 	    cntr_crnc    = crnc_id
        AND cntr_pool    = pool_id
        AND cntr_pers    = pers_id
	AND invoice_cntr = cntr_id
	AND invoice_sent IS NULL
	AND invoice_paid IS NULL
	AND invoice_due <= date_trunc('month', now() + interval '2 month')
			   - interval '1 second'
      ORDER BY invoice_due, contract;

COMMENT ON VIEW  invoice_next_month_rep IS 'Invoices to send this month';
GRANT SELECT ON invoice_next_month_rep TO GROUP ptpdemo_user;


DROP VIEW invoice_paid_this_month_rep;
CREATE VIEW invoice_paid_this_month_rep AS
      SELECT 
	'<a target=_new href=?action=edit&table=invoice&id=' || 
	invoice_id || '>Edit</a>' AS Edit,
        invoice_id,
        cntr_hid || ' - ' || cntr_name AS contract,
	pool_hid || ':' || pers_sign as owner,
        invoice_due,invoice_sent,invoice_paid,
        ROUND(invoice_work_nat::numeric,2) AS invoice_work_nat, crnc_hid
      FROM invoice, cntr, pool, pers, crnc
      WHERE  
  	    cntr_crnc    = crnc_id
        AND cntr_pool    = pool_id
        AND cntr_pers    = pers_id
	AND invoice_cntr = cntr_id 
	AND date_trunc('month', invoice_paid) = date_trunc('month', now())
      ORDER BY invoice_due, contract;

COMMENT ON VIEW  invoice_paid_this_month_rep IS 'Invoices paid this month';
GRANT SELECT ON invoice_paid_this_month_rep TO GROUP ptpdemo_user;


DROP VIEW invoice_paid_last_month_rep;
CREATE VIEW invoice_paid_last_month_rep AS
      SELECT 
	'<a target=_new href=?action=edit&table=invoice&id=' || 
	invoice_id || '>Edit</a>' AS Edit,
        invoice_id,
        cntr_hid || ' - ' || cntr_name AS contract,
	pool_hid || ':' || pers_sign as owner,
        invoice_due,invoice_sent,invoice_paid,
        ROUND(invoice_work_nat::numeric,2) AS invoice_work_nat, crnc_hid
      FROM invoice, cntr, pool, pers, crnc
      WHERE  
	    cntr_crnc    = crnc_id
        AND cntr_pool    = pool_id
        AND cntr_pers    = pers_id
	AND invoice_cntr = cntr_id 
	AND date_trunc('month', invoice_paid) = date_trunc('month', (now() - interval '1 month'))
      ORDER BY invoice_due, contract;

COMMENT ON VIEW  invoice_paid_last_month_rep IS 'Invoices paid last month';
GRANT SELECT ON invoice_paid_last_month_rep TO GROUP ptpdemo_user;

DROP VIEW invoice_open_rep;
CREATE VIEW invoice_open_rep AS
      SELECT 
	'<a target=_new href=?action=edit&table=invoice&id=' || 
	invoice_id || '>Edit</a>' AS Edit,
        invoice_id,
        cntr_hid || ' - ' || cntr_name AS contract,
	pool_hid || ':' || pers_sign as owner,
        invoice_due, invoice_sent,
        invoice_work_nat, crnc_hid
      FROM invoice, cntr, pool, pers, crnc
      WHERE  
	    cntr_crnc     = crnc_id
        AND cntr_pool     = pool_id
        AND cntr_pers     = pers_id
        AND invoice_cntr  = cntr_id 
	AND invoice_sent IS NOT NULL
	AND invoice_paid IS NULL
      ORDER BY invoice_sent, contract;

COMMENT ON VIEW  invoice_open_rep IS 'Invoices open';
GRANT SELECT ON invoice_open_rep TO GROUP ptpdemo_user;

DROP VIEW invoice_overdue_rep;
CREATE VIEW invoice_overdue_rep AS
      SELECT 
	'<a target=_new href=?action=edit&table=invoice&id=' || 
	invoice_id || '>Edit</a>' AS Edit,
        invoice_id,
        cntr_hid || ' - ' || cntr_name AS contract,
 	pool_hid || ':' || pers_sign as owner,
        invoice_due, invoice_sent,
        invoice_work_nat, crnc_hid
     FROM invoice, cntr, pool, pers, crnc
      WHERE  
 	    cntr_crnc     = crnc_id
        AND cntr_pool     = pool_id
        AND cntr_pers     = pers_id
        AND invoice_cntr  = cntr_id 
	AND invoice_paid IS NULL
	AND invoice_sent <= date_trunc('day',(now() - interval '1 month'))
      ORDER BY invoice_sent, contract;

COMMENT ON VIEW  invoice_overdue_rep IS 'Invoices overdue';
GRANT SELECT ON  invoice_overdue_rep TO GROUP ptpdemo_user;

-- calculate expense based on entries in woty_cost

DROP VIEW wolo_expense_view;
CREATE OR REPLACE VIEW wolo_expense_view AS
        SELECT wolo_id,
               (wolo_val * (SELECT woty_cost_rate FROM woty_cost
                            WHERE woty_cost_woty = wolo_woty
                              AND woty_cost_start <= wolo_date
                            ORDER BY woty_cost_start DESC
                            LIMIT 1))::numeric(9,2) as wolo_chf,
               wolo_cntr,
               wolo_invoice        
          FROM wolo
          WHERE wolo_woty in (SELECT woty_cost_woty FROM woty_cost join woty on (woty_cost_woty = woty_id ) WHERE woty_unit <> 7 );

GRANT SELECT ON wolo_expense_view TO GROUP ptpdemo_user;

INSERT INTO meta_tables 
    VALUES ('wolo_expense_view', 'hide','1');

DROP VIEW cntr_finance_rep;
CREATE OR REPLACE VIEW cntr_finance_rep AS
      SELECT cntr_id,
             cntr_hid,
             cust_last,
             cntr_name,
             cntr_offer,
             cntr_order,
             pool_hid,
             pers_sign as cntr_pers,
             cntr_expinc,
             crnc_hid,             
             cntr_value,
             round_05(( SELECT SUM(invoice_work_nat) FROM invoice WHERE invoice_cntr = cntr_id AND ( invoice_sent IS NOT NULL OR invoice_paid is not null)))::numeric(9,2) AS work_invoiced,
             round_05(( SELECT SUM(invoice_work_nat) FROM invoice WHERE invoice_cntr = cntr_id AND ( invoice_sent IS NULL     AND invoice_paid is null ) AND invoice_due <= date_trunc('month', now() + interval '2 month') - interval '1 second'))::numeric(9,2) AS work_due,
             round_05(( SELECT SUM(invoice_work_nat) FROM invoice WHERE invoice_cntr = cntr_id AND invoice_sent IS NOT NULL   AND invoice_paid IS NULL ))::numeric(9,2) AS work_waiting,
             round_05(( SELECT SUM(invoice_work_nat) FROM invoice WHERE invoice_cntr = cntr_id AND invoice_sent IS NULL))::numeric(9,2) AS work_planned,
             round_05( cntr_value - ( SELECT SUM(invoice_work_nat) FROM invoice           WHERE invoice_cntr = cntr_id ) )::numeric(9,2) AS work_unplanned,
             round_05( crnc_rate  * ( SELECT SUM(wolo_chf)         FROM wolo_expense_view WHERE wolo_cntr = cntr_id AND wolo_invoice IS NULL ) )::numeric(9,2) AS expense_open,
             '<a target="ptp_invoices" href="?search_field001=contract;search_value001=' || cntr_hid || ';table=invoice;action=list">E</a>' as E
        FROM cntr join pers on (cntr_pers = pers_id)
                  join pool on (cntr_pool = pool_id)
                  join crnc on (crnc_id = cntr_crnc)
                  join cust on (cntr_cust = cust_id)
        WHERE ( ( cntr_end IS NULL or cntr_end > ( CURRENT_DATE - '6 months'::interval)) 
          AND cntr_order is not null
          AND ( cntr_value > 0 or cntr_value is null) )
          OR  EXISTS ( SELECT invoice_cntr FROM invoice WHERE invoice_cntr = cntr_id and invoice_paid  is null )
        ORDER BY cntr_hid;

COMMENT ON VIEW cntr_finance_rep IS 'Contract Finance View';
COMMENT ON COLUMN cntr_finance_rep.cntr_hid IS 'Auftrag';
COMMENT ON COLUMN cntr_finance_rep.cntr_name IS 'Auftragsbezeichnung';
COMMENT ON COLUMN cntr_finance_rep.pool_hid IS 'Pool';
COMMENT ON COLUMN cntr_finance_rep.cntr_offer IS 'Offeriert';
COMMENT ON COLUMN cntr_finance_rep.cntr_order IS 'Bestellt';
COMMENT ON COLUMN cntr_finance_rep.cntr_pers IS 'Owner';
COMMENT ON COLUMN cntr_finance_rep.cntr_value IS 'Auftragstotal';
COMMENT ON COLUMN cntr_finance_rep.crnc_hid IS 'Währung';
COMMENT ON COLUMN cntr_finance_rep.cntr_expinc IS 'ExpInc';
COMMENT ON COLUMN cntr_finance_rep.work_invoiced IS 'Verrechnet';
COMMENT ON COLUMN cntr_finance_rep.work_due IS 'To Bill';
COMMENT ON COLUMN cntr_finance_rep.work_waiting IS 'Un Paid';
COMMENT ON COLUMN cntr_finance_rep.work_planned IS 'Geplant';
COMMENT ON COLUMN cntr_finance_rep.work_unplanned IS 'Ungeplant';
COMMENT ON COLUMN cntr_finance_rep.expense_open IS 'Open Exp [CHF]';

GRANT SELECT ON cntr_finance_rep TO GROUP ptpdemo_user;

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
    IF  TG_OP = 'INSERT' THEN
        IF not ingroup('ptpdemo_admin') 
	   and not exists (SELECT * FROM prodpers,acti
            WHERE NEW.wolo_pers = prodpers_pers
                  AND NEW.wolo_acti = acti_id
                  AND prodpers_prod = acti_prod )
           and not exists (SELECT * FROM prod,acti
            WHERE NEW.wolo_pers = prod_pers and acti_prod=prod_id )
           THEN
           RAISE EXCEPTION 'The selected User is not subscribed to the function/project this activity is part of';
	END IF;
    END IF;


   
    IF TG_OP = 'UPDATE' OR TG_OP = 'INSERT' THEN
       IF  NEW.wolo_pers != pers_hid2id(current_user)
         AND  not ( ingroup('ptpdemo_admin') )
       THEN
         RAISE EXCEPTION 'Do not change other peoples entries';
       END IF;

       IF exists ( SELECT acti_id FROM acti 
                    WHERE NEW.wolo_acti=acti_id
		      AND ( NEW.wolo_date < acti_start
			    OR NEW.wolo_date > acti_end ))
       THEN
           RAISE EXCEPTION 'The selected activity is not valid for the selected date';
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

-- deactivated in the transition periode
-- CREATE RULE acti_linkage_rule AS 
--       ON UPDATE TO acti
--       WHERE ( NEW.acti_prod != OLD.acti_prod OR NEW.acti_prod != OLD.acti_prod )
--	     AND EXISTS (SELECT wolo_id
--        	         FROM wolo WHERE wolo_acti = NEW.acti_id )
--       DO INSTEAD SELECT elog('Can not change activity/product and activity/function-project linking as there are worklog entries pointing to the activity');
--

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

-- ##############################################################################
-- Auslastungsevaluation
-- ##############################################################################
DROP TYPE month_list_type;
CREATE TYPE month_list_type AS (first_day DATE, last_day DATE);
CREATE OR REPLACE FUNCTION month_list(start_date DATE, months INT4) returns SETOF month_list_type AS $CODE$
DECLARE
    i INT4;
    row month_list_type;
BEGIN
    FOR i in 0..months LOOP
        row.first_day :=  date_trunc('month',start_date) + (i || ' months')::interval;
        row.last_day  := row.first_day + interval '1 month';
        RETURN NEXT row;
    END LOOP;        
END;
$CODE$ 
LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION minimum(anyarray)
returns anyelement as $$
select min($1[i]) from generate_series(array_lower($1,1),
array_upper($1,1)) g(i);
$$ language sql immutable strict;

CREATE OR REPLACE FUNCTION maximum(anyarray)
returns anyelement as $$
select max($1[i]) from generate_series(array_lower($1,1),
array_upper($1,1)) g(i);
$$ language sql immutable strict;

CREATE or REPLACE VIEW work_load_rep AS
SELECT pool_hid as pool,to_char(first_day,'YYYY-MM') as mon,
     ( sum( 
     ( MAXIMUM(ARRAY[first_day,MINIMUM(ARRAY[COALESCE(cntr_remdat,cntr_workend,cntr_end),last_day])]) -
        MINIMUM(ARRAY[last_day, MAXIMUM(ARRAY[COALESCE(cntr_workstart,cntr_start),first_day])]) 
      )
      * COALESCE(cntr_hours,0)
      / (coalesce(cntr_workend,cntr_end) - coalesce(cntr_workstart,cntr_start))) + 
     coalesce(sum (
      ( MAXIMUM(ARRAY[first_day,MINIMUM(ARRAY[COALESCE(cntr_workend,cntr_end),last_day])]) -
        MINIMUM(ARRAY[last_day, MAXIMUM(ARRAY[COALESCE(cntr_remdat,cntr_workend,cntr_end),first_day])]) 
      )
       * COALESCE(cntr_remhrs,0) 
       / (coalesce(cntr_workend,cntr_end) - cntr_remdat)
     ),0) )::integer as planned,
     sum(wolo_val)::integer as actual
  from cntr 
       join pool on (cntr_pool = pool_id) 
       join month_list((current_date - interval '12 months')::date,16) as g 
            on ((COALESCE(cntr_workstart,cntr_start),COALESCE(cntr_workend,cntr_end)) 
                 OVERLAPS (first_day,last_day))    
       left outer join (
        select wolo_cntr,first_day as first_day_inner,sum(wolo_val) as wolo_val
        from month_list((current_date - interval '12 months')::date,16) as k
             join wolo on (wolo_date between k.first_day and k.last_day)
             join woty on (wolo_woty = woty_id and woty_unit = 7)
        group by wolo_cntr,k.first_day
       ) x on (cntr_id = x.wolo_cntr and first_day = x.first_day_inner)
       where COALESCE(cntr_workend,cntr_end) is not null
       and COALESCE(cntr_workstart,cntr_start) is not null
       and cntr_hours is not null
       and cntr_order is not null
       group by pool_hid,first_day order by pool_hid,first_day;


COMMENT ON VIEW work_load_rep IS 'Workload Preview';
COMMENT ON COLUMN work_load_rep.mon IS 'Month';
COMMENT ON COLUMN work_load_rep.planned IS 'Planned';
COMMENT ON COLUMN work_load_rep.actual IS 'Actual';
COMMENT ON COLUMN work_load_rep.pool IS 'Pool';

GRANT SELECT ON work_load_rep TO GROUP ptpdemo_user;


-- ##############################################################################
-- Expense Management
-- ##############################################################################

DROP TABLE paymean CASCADE;
CREATE TABLE paymean (
   paymean_id      SERIAL NOT NULL PRIMARY KEY,                          	  -- Unique ID
   paymean_name    TEXT   NOT NULL                              -- Which Wolo does this concern
) WITH OIDS;

GRANT SELECT,UPDATE ON paymean_paymean_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON paymean TO GROUP ptpdemo_user;

COMMENT ON TABLE paymean IS 'Z Means of Payment';
COMMENT ON COLUMN paymean.paymean_id IS 'ID';   
COMMENT ON COLUMN paymean.paymean_name IS 'Name';


DROP VIEW paymean_combo;
CREATE OR REPLACE VIEW paymean_combo AS
       SELECT paymean_id AS id, paymean_name  AS text 
       FROM paymean ORDER BY paymean_name;

GRANT SELECT ON paymean_combo TO GROUP ptpdemo_user;



DROP TABLE expegroup CASCADE;
CREATE TABLE expegroup (
   expegroup_id     SERIAL NOT NULL PRIMARY KEY, -- Unique ID
   expegroup_name   TEXT   NOT NULL              -- What kind of expense group
) WITH OIDS;

GRANT SELECT,UPDATE ON expegroup_expegroup_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON expegroup TO GROUP ptpdemo_user;

COMMENT ON TABLE expegroup IS 'Z Expense Type Groups';
COMMENT ON COLUMN expegroup.expegroup_id IS 'ID';   
COMMENT ON COLUMN expegroup.expegroup_name IS 'Name';

CREATE OR REPLACE VIEW expegroup_combo AS
  SELECT expegroup_id AS id, expegroup_name AS text
    FROM expegroup ORDER BY expegroup_name;
GRANT SELECT ON expegroup_combo TO GROUP ptpdemo_user;

-- ##############################################################################
-- Pools to combine contracts
-- ##############################################################################

DROP TABLE pool CASCADE;
CREATE TABLE pool (
   pool_id     SERIAL         NOT NULL PRIMARY KEY,                          	  -- Unique ID
   pool_hid    VARCHAR(4)     NOT NULL CHECK (pool_hid ~ '[A-Z]+') UNIQUE,   	  -- Human Readable Unique ID
   pool_name   TEXT           NOT NULL CHECK (pool_name != ''),       		  -- Full Name of Work Type
   pool_pers    INT4 NOT NULL REFERENCES pers DEFAULT pers_hid2id(current_user)  -- Verantwortliche Person fuer den Bereich
) WITH OIDS;

GRANT SELECT,UPDATE ON pool_pool_id_seq TO GROUP ptpdemo_admin;
GRANT SELECT ON pool TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON pool TO GROUP ptpdemo_admin;

COMMENT ON TABLE pool IS 'Z Contract Pool';
COMMENT ON COLUMN pool.pool_id IS 'ID';
COMMENT ON COLUMN pool.pool_hid IS 'Type';
COMMENT ON COLUMN pool.pool_name IS 'Full Name';
COMMENT ON COLUMN pool.pool_pers IS 'Pool Manager';


DROP VIEW pool_combo;
CREATE OR REPLACE VIEW pool_combo AS
       SELECT pool_id AS id, pool_hid || '--' || pool_name  AS text 
       FROM pool ORDER BY pool_hid;

GRANT SELECT ON pool_combo TO GROUP ptpdemo_user;

DROP VIEW pool_list;
CREATE VIEW pool_list AS
       SELECT pool_hid, pool_name, pers_hid
       FROM pool, pers
       WHERE pers_id=pool_pers;

GRANT SELECT ON pool_list TO GROUP ptpdemo_user;

-- ###########################################################################
-- Mailinglist Support
-- ###########################################################################

DROP TABLE mlist CASCADE;
CREATE TABLE mlist (
   mlist_id     SERIAL         NOT NULL PRIMARY KEY,                           -- Unique ID
   mlist_hid    VARCHAR(6)     NOT NULL CHECK (mlist_hid ~ '[0-9a-zA-Z]+') UNIQUE,   -- Human Readable Unique ID
   mlist_name   TEXT           NOT NULL CHECK (mlist_name != ''),       -- Full Name of Work Type
   mlist_term   DATE           -- termination date
) WITH OIDS;

GRANT SELECT,UPDATE ON mlist_mlist_id_seq TO GROUP ptpdemo_user;
GRANT SELECT ON mlist TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON mlist TO GROUP ptpdemo_user;

COMMENT ON TABLE mlist IS 'Z Mailinglists';
COMMENT ON COLUMN mlist.mlist_id IS 'ID';
COMMENT ON COLUMN mlist.mlist_hid IS 'Short Name';
COMMENT ON COLUMN mlist.mlist_name IS 'Full Name';
COMMENT ON COLUMN mlist.mlist_term IS 'Do not show after';


DROP VIEW mlist_combo;
CREATE OR REPLACE VIEW mlist_combo AS
       SELECT mlist_id AS id, mlist_hid || '--' || mlist_name  AS text 
       FROM mlist WHERE mlist_term is null or mlist_term >= CURRENT_DATE ORDER BY mlist_hid;

GRANT SELECT ON mlist_combo TO GROUP ptpdemo_user;

-- ##############################################################################
-- Mailinglist Memberships
-- ##############################################################################

DROP TABLE mlmbr CASCADE;
CREATE TABLE mlmbr (
   mlmbr_id     SERIAL         NOT NULL PRIMARY KEY,               -- Unique ID
   mlmbr_cust   INT4           NOT NULL REFERENCES cust(cust_id),   -- Customer
   mlmbr_mlist   INT4          NOT NULL REFERENCES mlist(mlist_id),   -- Mailinglist
   mlmbr_address INT4          REFERENCES address(address_id),      -- Address
   mlmbr_cyberaddr INT4        REFERENCES cyberaddr(cyberaddr_id),  -- Cyber Address
   mlmbr_start   DATE          NOT NULL DEFAULT CURRENT_DATE,
   mlmbr_end     DATE,
   mlmbr_next    DATE
) WITH OIDS;

CREATE OR REPLACE RULE mlmbr_custaddress_upd_rule AS 
       ON UPDATE TO mlmbr
       WHERE NEW.mlmbr_address IS NOT NULL
             AND NOT EXISTS (SELECT 1
                         FROM address 
                         WHERE NEW.mlmbr_cust = address_cust
                           AND NEW.mlmbr_address = address_id )
       DO INSTEAD UPDATE elog set elog=false where elog('The selected address does not belong to the selected customer');

CREATE OR REPLACE RULE mlmbr_custaddress_ins_rule AS 
       ON INSERT TO mlmbr
       WHERE NEW.mlmbr_address IS NOT NULL
             AND NOT EXISTS (SELECT 1
                         FROM address 
                         WHERE NEW.mlmbr_cust = address_cust
                           AND NEW.mlmbr_address = address_id )
       DO INSTEAD UPDATE elog set elog=false where elog('The selected address does not belong to the selected customer');


INSERT INTO meta_fields VALUES ('mlmbr','mlmbr_mlist', 'copy','1');

GRANT SELECT,UPDATE ON mlmbr_mlmbr_id_seq TO GROUP ptpdemo_user;
GRANT SELECT ON mlmbr TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON mlmbr TO GROUP ptpdemo_user;

COMMENT ON TABLE mlmbr IS 'Z Mailinglist Memberships';
COMMENT ON COLUMN mlmbr.mlmbr_id IS 'ID';
COMMENT ON COLUMN mlmbr.mlmbr_mlist IS 'Mailinglist';
COMMENT ON COLUMN mlmbr.mlmbr_cust IS 'Customer';
COMMENT ON COLUMN mlmbr.mlmbr_address IS 'Address';
COMMENT ON COLUMN mlmbr.mlmbr_cyberaddr IS 'Cyber Address';
COMMENT ON COLUMN mlmbr.mlmbr_start IS 'Start';
COMMENT ON COLUMN mlmbr.mlmbr_end IS 'End';
COMMENT ON COLUMN mlmbr.mlmbr_next IS 'Next Contact';


DROP VIEW mlmbr_list;
CREATE OR REPLACE VIEW mlmbr_list AS
       SELECT  mlmbr_id, 
              mlist_hid || CASE WHEN mlist_term is null or mlist_term >= current_date THEN '' ELSE ' (Terminated)' END  as mlmbr_mlist, 
              cust_id, 
              cust_last || coalesce(', ' || cust_first,'') AS mlmbr_cust,
	      cust_start, cust_end,
              COALESCE(address_company,address_street) || ' ' || address_town  AS mlmbr_address,
              cyberaddr_url AS mlmbr_cyberaddr,
              mlmbr_start,
              mlmbr_end
       FROM mlmbr 
       join cust on mlmbr_cust = cust_id
       join mlist on mlmbr_mlist = mlist_id
       left join address on mlmbr_address = address_id
       left join cyberaddr on cyberaddr_id = mlmbr_cyberaddr
       WHERE mlmbr_cust=cust_id AND mlmbr_mlist = mlist_id;

GRANT SELECT ON mlmbr_list TO GROUP ptpdemo_user;

COMMENT ON COLUMN mlmbr_list.cust_id IS 'Cust'; 

drop view mailinglist_rep ;
CREATE OR REPLACE VIEW mailinglist_rep AS
       SELECT  ml_id,
               cust_title as cu_title,
               cust_id as cu_id,
               cust_last as cu_last_name,
               cust_first as cu_first_name,      
               pers_first as cu_opc_first,          
               pers_last as cu_opc_last,          
               address_company as ad_company_name,
               address_street as ad_address,
               cyberaddr_url as email,
               COALESCE(address_zip || ' ','') || address_town as ad_zip_town,
               address_country as ad_country,
               CASE WHEN cust_gender in (1,3) THEN 'e ' || COALESCE(cust_title, 'Frau')
                    WHEN cust_gender = 5 THEN 'er ' || COALESCE(cust_title, 'Herr')
                    ELSE '??????????'
               END as anrede,
               cust_actitle as cu_academic       
       FROM (
               SELECT mlmbr_cust,
                      mlmbr_address,
                      cyberaddr_url,
                      array_to_string(array_accum(mlist_hid), ' '::text) as ml_id        
               FROM mlmbr
                    join mlist on (mlmbr_mlist = mlist_id)
                    left join cyberaddr on (mlmbr_cyberaddr = cyberaddr_id)
               WHERE mlmbr_end is null or mlmbr_end > current_date
               GROUP BY mlmbr_cust,mlmbr_address,cyberaddr_url
            ) as x
            join cust on (mlmbr_cust = cust_id)
            left join pers on (cust_pers = pers_id)
            left join address on (mlmbr_address = address_id)
       WHERE (cust_end is null or cust_end > current_date)
       ORDER BY pers_last, address_country, address_zip;

GRANT SELECT ON mailinglist_rep TO GROUP ptpdemo_user;
COMMENT ON VIEW  mailinglist_rep IS 'Mailinglist Report';

-- migration table

DROP TABLE exp2wolo CASCADE;
CREATE TABLE exp2wolo (
   exp2wolo_id SERIAL NOT NULL PRIMARY KEY,
   exp2wolo_hid VARCHAR(6) NOT NULL,
   exp2wolo_woty INTEGER NOT NULL REFERENCES woty,
   exp2wolo_acti INTEGER NOT NULL REFERENCES acti,
   exp2wolo_factor FLOAT NOT NULL DEFAULT 1
) WITH OIDS;

GRANT SELECT,UPDATE ON exp2wolo_exp2wolo_id_seq TO GROUP ptpdemo_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON exp2wolo TO GROUP ptpdemo_user;

   

-- ##############################################################################
-- Inventory
-- ##############################################################################

DROP TABLE inventory;
DROP SEQUENCE inventory_inventory_id_seq;

CREATE TABLE inventory (
   inventory_id          SERIAL NOT NULL PRIMARY KEY,                -- Unique ID
   inventory_name        TEXT NOT NULL CHECK (inventory_name != ''),
   inventory_kind        TEXT,
   inventory_responsible INT4 NOT NULL REFERENCES pers,
   inventory_delivery    DATE DEFAULT CURRENT_DATE,
   inventory_warentyend  DATE,
   inventory_termination DATE,
   inventory_cost        NUMERIC(9,2),
   inventory_distributor TEXT,
   inventory_location    TEXT,
   inventory_serial      TEXT,
   inventory_scanned     BOOLEAN,
   inventory_note        TEXT
) WITH OIDS;

COMMENT ON TABLE inventory IS 'G Inventar';
COMMENT ON COLUMN inventory.inventory_id           IS 'ID';
COMMENT ON COLUMN inventory.inventory_name         IS 'Name';
COMMENT ON COLUMN inventory.inventory_kind         IS 'Art';
COMMENT ON COLUMN inventory.inventory_delivery     IS 'Delivery Date';
COMMENT ON COLUMN inventory.inventory_warentyend   IS 'Warenty End Date';
COMMENT ON COLUMN inventory.inventory_termination  IS 'Termination Date';
COMMENT ON COLUMN inventory.inventory_responsible  IS 'Responsible';
COMMENT ON COLUMN inventory.inventory_cost         IS 'Original Price';  
COMMENT ON COLUMN inventory.inventory_location     IS 'Location';
COMMENT ON COLUMN inventory.inventory_distributor  IS 'Lieferant'; 
COMMENT ON COLUMN inventory.inventory_serial       IS 'Serialnumber';
COMMENT ON COLUMN inventory.inventory_scanned      IS 'Receipt Scanned'; 
COMMENT ON COLUMN inventory.inventory_note         IS 'Bemerkung';

INSERT INTO meta_fields  VALUES ('inventory','inventory_note','widget','area');
INSERT INTO meta_fields  VALUES ('inventory','inventory_distributor','widget','text(size=50)');

GRANT ALL ON inventory TO GROUP ptpdemo_user;
GRANT ALL ON inventory_inventory_id_seq TO ptpdemo_user;

DROP VIEW inventory_list;
CREATE VIEW inventory_list AS
      SELECT  inventory_id , inventory_name, inventory_kind, inventory_serial, inventory_cost,
              inventory_delivery, inventory_warentyend, inventory_termination,
              inventory_distributor, pers_hid as inventory_responsible,
              inventory_location, inventory_scanned, inventory_note
      FROM inventory left join pers on (inventory_responsible = pers_id);

GRANT SELECT ON inventory_list TO GROUP ptpdemo_user;

COMMENT ON COLUMN inventory_list.inventory_scanned      IS 'Scan';

-- ##############################################################################
-- Pool Report
-- ##############################################################################

CREATE OR REPLACE VIEW pool_work_rep AS
select date_trunc('month',wolo_date)::date as month,
       pool_hid as pool,
       owner.pers_sign as owner,
       worker.pers_sign as worker,
       woty_hid as woty, 
       sum(wolo_val) as hours
  from cntr 
  join pers owner on (cntr_pers = owner.pers_id)
  join pool on (cntr_pool = pool_id)
  join wolo on (wolo_cntr = cntr_id)
  join pers worker on (wolo_pers = worker.pers_id)
  join woty on (wolo_woty = woty_id)
  group by month,
           pool_hid,        
           owner,
           worker,
           woty_hid
  UNION
select date_trunc('month',wolo_date)::date as month,
       pool_hid as pool,
       owner.pers_sign as owner,
       'TOTAL' as worker,                
       woty_hid as woty, 
       sum(wolo_val) as hours
  from cntr 
  join pers owner on (cntr_pers = owner.pers_id)
  join pool on (cntr_pool = pool_id)
  join wolo on (wolo_cntr = cntr_id)
  join woty on (wolo_woty = woty_id)
  group by month,
           pool_hid,
           owner,   
           woty_hid 
  order by month desc,pool;      

COMMENT ON VIEW pool_work_rep IS 'Pool Work Report';
GRANT ALL ON pool_work_rep TO GROUP ptpdemo_user;
