CREATE USER dbtoria_test_user PASSWORD 'abc';
CREATE USER dbtoria_test_admin PASSWORD 'xyz';

DROP DATABASE IF EXISTS dbtoria_test_db;

CREATE DATABASE dbtoria_test_db WITH OWNER = dbtoria_test_admin ENCODING 'UTF8' TEMPLATE=template0;
GRANT ALL ON DATABASE dbtoria_test_db TO  dbtoria_test_admin;

\connect dbtoria_test_db
SET SESSION AUTHORIZATION 'dbtoria_test_admin';
SET search_path = public, pg_catalog;

DROP TABLE IF EXISTS chocolate CASCADE;

CREATE TABLE chocolate (
    chocolate_id INT NOT NULL PRIMARY KEY,
    chocolate_flavour VARCHAR(50)
);

INSERT INTO chocolate VALUES
   (1,'Dark chocolate'),
   (2,'Semisweet chocolate'),
   (3,'Milk chocolate'),
   (4,'White chocolate');

GRANT SELECT, UPDATE ON
   chocolate
 TO dbtoria_test_user,dbtoria_test_admin;

DROP TABLE IF EXISTS favourite;

CREATE TABLE favourite (
    favourite_id SERIAL NOT NULL PRIMARY KEY,
    favourite_name VARCHAR(50) NOT NULL,
    favourite_chocolate INT NOT NULL REFERENCES chocolate
);

GRANT SELECT, UPDATE ON favourite_favourite_id_seq TO dbtoria_test_admin;

GRANT SELECT, UPDATE, INSERT, DELETE ON
    favourite
 TO dbtoria_test_admin;

GRANT SELECT, UPDATE ON
   favourite_favourite_id_seq
 TO dbtoria_test_user;

GRANT SELECT, INSERT, UPDATE ON
   favourite
 TO dbtoria_test_user;
