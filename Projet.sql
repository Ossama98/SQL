drop table  CATALOGUE_O cascade constraints;
drop table  EXEMPLAIRE_O cascade constraints;
drop table  AUTEUR_O cascade constraints;
drop table  BIBLIOTHEQUE_O cascade constraints;
drop table  EMPRUNT_O cascade constraints;
drop table  ADHERENT_O cascade constraints;

drop type   AUTEUR_T force;
drop type   TAB_REF_AUTEURS_T force ;
drop type   CATALOGUE_T force;
drop type   EXEMPLAIRE_T force;
drop type   TABEXEMPLAIRES_T force;
drop type   BIBLIOTHEQUE_T force;
drop type   TABPRENOMS_T force;
drop type   ADHERENT_T force;
drop type   TAB_REF_BIBLIOTHEQUE_T force;
drop type   EMPRUNT_T force;

-- Création des types

CREATE OR REPLACE TYPE AUTEUR_T
/

CREATE OR REPLACE TYPE TAB_REF_AUTEURS_T AS TABLE OF REF AUTEUR_T
/

CREATE OR REPLACE TYPE CATALOGUE_T
/

CREATE OR REPLACE TYPE CATALOGUE_T AS OBJECT(
CATNO               NUMBER(4),
TITRE               VARCHAR2(20),
ANNEE_EDITION       DATE,
MAISON_EDITION      VARCHAR2(20),
REF_AUTEURS         TAB_REF_AUTEURS_T,
DESCRIPTIONS        CLOB,
MAP MEMBER FUNCTION compAnneeEDITION return DATE,  -- comparer avec ANNEE_EDITION décroissant
MEMBER PROCEDURE consulterAuteurs  
);
/

CREATE OR REPLACE TYPE EXEMPLAIRE_T AS OBJECT(
EXNO                  NUMBER(4),
REF_CATALOGUE         REF CATALOGUE_T,
MAP MEMBER FUNCTION compID return NUMBER -- comparer avec ID croissant
);
/

CREATE OR REPLACE TYPE TABEXEMPLAIRES_T AS TABLE OF EXEMPLAIRE_T
/

CREATE OR REPLACE TYPE BIBLIOTHEQUE_T AS OBJECT(
ID                          NUMBER(4),
REGION                      VARCHAR(20),
EXEMPLAIRES                 TABEXEMPLAIRES_T,
ADDRESSE                    VARCHAR(20),
VILLE                       VARCHAR(20),
MAP MEMBER FUNCTION compRegionVille return VARCHAR2, -- comparer avec région||ville
MEMBER PROCEDURE ajoutExemplaire(exemplaire in EXEMPLAIRE_T)
);
/

CREATE OR REPLACE TYPE ADHERENT_T
/

CREATE OR REPLACE TYPE EMPRUNT_T AS OBJECT(
ID                      NUMBER(4),
REF_ADHERENT            REF ADHERENT_T,
DATE_START              DATE ,
DATE_END                DATE , --date de fin de l'emprunt
DATE_RETOUR             DATE , --date effective de retour
REF_EXEMPLAIRE          REF EXEMPLAIRE_T,
MAP MEMBER FUNCTION compDateEnd return DATE, -- comparer avec DATE_END croissant
MEMBER FUNCTION prolongerDateEnd(nbJour in NUMBER) return DATE,
MEMBER PROCEDURE testRetard
);
/

CREATE OR REPLACE TYPE TABPRENOMS_T AS VARRAY(4) OF VARCHAR2(40);
/

CREATE OR REPLACE TYPE TAB_REF_BIBLIOTHEQUE_T AS TABLE OF REF BIBLIOTHEQUE_T
/

CREATE OR REPLACE TYPE ADHERENT_T AS OBJECT(
NUMERO_ADHERENT            NUMBER(4),
NOM                        VARCHAR2(20),
PRENOMS                    TABPRENOMS_T,
REF_BIBLIOTHEQUE           TAB_REF_BIBLIOTHEQUE_T,
ADRESSE                    VARCHAR2(20),
PHONE                      VARCHAR2(20),
EMAIL                      VARCHAR2(20),
DATE_DE_NAISSANCE          DATE,
DATE_D_ADHESION            DATE,
VILLE                      VARCHAR2(20),
MAP MEMBER FUNCTION compNomPrenomsVille return VARCHAR2 -- comparer avec NOM||PRENOM||VILLE
);
/

CREATE OR REPLACE TYPE AUTEUR_T AS OBJECT(
ID                          NUMBER(4),
NOM                         VARCHAR2(20),
PRENOMS                     TABPRENOMS_T,
DATE_DE_NAISSANCE           DATE,
DATE_DE_DECES               DATE,
NATIONALITE                 VARCHAR(20),
VILLE                       VARCHAR(20),
BIOGRAPHIE                  CLOB,
MAP MEMBER FUNCTION compNomPrenomsNaissance return VARCHAR2 -- comparer avec NOM||PRENOM||DATE_DE_NAISSANCE

);
/

--CREATE OR REPLACE TYPE TAB_REF_BIBLIOTHEQUE_T AS TABLE OF REF BIBLIOTHEQUE_T
--/

-- Création des tables
CREATE TABLE CATALOGUE_O OF CATALOGUE_T(
CONSTRAINT PK_CATALOGUE_O_CATNO PRIMARY KEY(CATNO),
CONSTRAINT NNL_CATALOGUE_O_TITRE TITRE NOT NULL 
)
NESTED TABLE REF_AUTEURS STORE AS TABLE_REF_AUTEURS ,
LOB(DESCRIPTIONS) STORE AS STORE_LOB_DESCRIPTIONS 
/

CREATE TABLE EXEMPLAIRE_O OF EXEMPLAIRE_T(
CONSTRAINT PK_EXEMPLAIRE_O_EXNO PRIMARY KEY(EXNO)
)
/

CREATE TABLE AUTEUR_O OF AUTEUR_T(
    CONSTRAINT PK_AUTEUR_O_ID PRIMARY KEY(ID),
    CONSTRAINT NNL_AUTEUR_O_NOM NOM NOT NULL,
    CONSTRAINT CHK_O_AUTEUR_NOM CHECK(NOM=upper(NOM)),
    CONSTRAINT NNL_AUTEUR_O_PRENOMS PRENOMS NOT NULL,
    CONSTRAINT NNL_AUTEUR_O_DATE_DE_NAISSANCE DATE_DE_NAISSANCE NOT NULL,
    CONSTRAINT NNL_AUTEUR_O_NATIONALITE NATIONALITE NOT NULL,
    CONSTRAINT NNL_AUTEUR_O_VILLE VILLE NOT NULL
)
LOB(BIOGRAPHIE) STORE AS storeLobBiographie
/

CREATE TABLE BIBLIOTHEQUE_O OF BIBLIOTHEQUE_T(
    CONSTRAINT PK_BIBLIOTHEQUE_O_ID PRIMARY KEY(ID),
    CONSTRAINT NNL_BIBLIOTHEQUE_O_REGION REGION NOT NULL,
    CONSTRAINT NNL_BIBLIOTHEQUE_O_ADDRESSE ADDRESSE NOT NULL,
    CONSTRAINT NNL_BIBLIOTHEQUE_O_VILLE VILLE NOT NULL
)
NESTED TABLE EXEMPLAIRES STORE AS TABLE_EXEMPLAIRES
/

CREATE TABLE EMPRUNT_O OF EMPRUNT_T(
    CONSTRAINT PK_EMPRUNT_O_ID PRIMARY KEY(ID),
    CONSTRAINT NNL_EMPRUNT_O_REF_ADHERENT REF_ADHERENT NOT NULL,
    CONSTRAINT NNL_EMPRUNT_O_DATE_START DATE_START NOT NULL,
    CONSTRAINT NNL_EMPRUNT_O_DATE_END DATE_END NOT NULL,
    CONSTRAINT NNL_EMPRUNT_O_REF_EXEMPLAIRE REF_EXEMPLAIRE NOT NULL,
    constraint CHK_EMPRUNT_O_DATE_START_END CHECK(DATE_START<DATE_END)
)
/

CREATE TABLE ADHERENT_O OF ADHERENT_T(
CONSTRAINT PK_ADHERENT_O_NUMERO_ADHERENT PRIMARY KEY(NUMERO_ADHERENT),
CONSTRAINT NNL_ADHERENT_O_NOM NOM NOT NULL,
CONSTRAINT NNL_ADHERENT_O_PHONE PHONE NOT NULL,
CONSTRAINT NNL_ADHERENT_O_DATE_D_ADHESION DATE_D_ADHESION NOT NULL,
CONSTRAINT NNL_ADHERENT_O_DATE_DE_NAISSANCE DATE_DE_NAISSANCE NOT NULL,
CONSTRAINT NNL_ADHERENT_O_VILLE VILLE NOT NULL
)
NESTED TABLE REF_BIBLIOTHEQUE STORE AS TABLE_REF_BIBLIOTHEQUE
/

ALTER TABLE TABLE_REF_BIBLIOTHEQUE 
	ADD (SCOPE FOR (column_value) IS BIBLIOTHEQUE_O);

-- Création des indexes
-- Indexes EMPRUNT
CREATE INDEX IDX_UNIQUE_EMPRUNT_DATE_START ON EMPRUNT_O(DATE_START);
CREATE INDEX IDX_UNIQUE_EMPRUNT_DATE_END ON EMPRUNT_O(DATE_END);

--Indexes ADHERENT
CREATE INDEX IDX_UNIQUE_ADHERENT_NOM ON ADHERENT_O(NOM);
CREATE INDEX IDX_UNIQUE_ADHERENT_VILLE ON ADHERENT_O(VILLE);
CREATE INDEX IDX__BIBLIOTHEQUE_NESTED_TABLE_ID ON TABLE_REF_BIBLIOTHEQUE(NESTED_TABLE_ID, COLUMN_VALUE);

-- Insertion des adherents

DECLARE
refAdh1 REF ADHERENT_T;

refAdh2 REF ADHERENT_T;

refAdh3 REF ADHERENT_T;

refAdh4 REF ADHERENT_T;

refAdh5 REF ADHERENT_T;

refAdh6 REF ADHERENT_T;

refAdh7 REF ADHERENT_T;

refAdh8 REF ADHERENT_T;

refAdh9 REF ADHERENT_T;

refAdh10 REF ADHERENT_T;

refAdh11 REF ADHERENT_T;

refAdh12 REF ADHERENT_T;

refAdh13 REF ADHERENT_T;

refAdh14 REF ADHERENT_T;

refAdh15 REF ADHERENT_T;

refAdh16 REF ADHERENT_T;

refAdh17 REF ADHERENT_T;

refAdh18 REF ADHERENT_T;

refAdh19 REF ADHERENT_T;

refAdh20 REF ADHERENT_T;

begin
INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    1, 'Martin', TABPRENOMS_T('Gabriel', 'A'), null, '26 boulevard Renaud', '+33-655-537-820', 'punkis@icloud.fr', to_date('11/02/1983', 'DD/MM/YYYY'), to_date('08/11/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh1;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    2, 'Bernard', TABPRENOMS_T('Léo', 'B'), null, '27 rue Barbe', '+33-735-554-648', 'skoch@yahoo.fr', to_date('18/02/1973', 'DD/MM/YYYY'), to_date('14/06/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh2;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    3, 'Thomas', TABPRENOMS_T('Raphaël', 'C'), null, '28 avenue de Martins', '+33-655-544-986', 'mrobshaw@live.fr', to_date('21/04/1988', 'DD/MM/YYYY'), to_date('11/01/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh3;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    4, 'Petit', TABPRENOMS_T('Arthur', 'D'), null, '29 place Charles', '+33-655-582-035', 'geekgrl@outlook.fr', to_date('23/05/1967', 'DD/MM/YYYY'), to_date('04/08/2020', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh4;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    5, 'Robert', TABPRENOMS_T('Louis', 'E'), null, '30 impasse Muller', '+33-775-557-450', 'malin@msn.fr', to_date('17/10/1984', 'DD/MM/YYYY'), to_date('28/06/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh5;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    6, 'Richard', TABPRENOMS_T('Emma', 'F'), null, '31 rue Lamy', '+33-785-550-994', 'hmbrand@sbcglobal.fr', to_date('25/08/1967', 'DD/MM/YYYY'), to_date('09/12/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh6;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    7, 'Durand', TABPRENOMS_T('Jade', 'E'), null, '32 rue Roy', '+33-655-552-115', 'zeitlin@hotmail.fr', to_date('26/01/1972', 'DD/MM/YYYY'), to_date('21/10/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh7;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    8, 'Dubois', TABPRENOMS_T('Louise', 'R'), null, '33 place Roger', '+33-655-584-492', 'lamky@gmail.fr', to_date('02/06/2001', 'DD/MM/YYYY'), to_date('01/04/2017', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh8;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    9, 'Moreau', TABPRENOMS_T('Lucas', 'R'), null, '34 avenue Peron', '+33-700-555-126', 'bryanw@live.fr', to_date('15/05/1994', 'DD/MM/YYYY'), to_date('26/06/2017', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh9;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    10, 'Laurent', TABPRENOMS_T('Adam', 'R'), null, '35 avenue Maurice', '+33-700-555-643', 'helger@att.fr', to_date('07/03/1989', 'DD/MM/YYYY'), to_date('15/04/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh10;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    11, 'Simon', TABPRENOMS_T('Maël', 'M'), null, '36 impasse Blanc', '+33-700-555-172', 'gator@msn.fr', to_date('27/02/1970', 'DD/MM/YYYY'), to_date('20/07/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh11;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    12, 'Michel', TABPRENOMS_T('Jules', 'J'), null, '37 place Lemaire', '+33-655-531-855', 'psharpe@verizon.fr', to_date('05/04/1966', 'DD/MM/YYYY'), to_date('23/12/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh12;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    13, 'Lefebvre', TABPRENOMS_T('Hugo', 'J'), null, '38 rue Simon', '+33-700-555-300', 'fangorn@mac.fr', to_date('10/04/1971', 'DD/MM/YYYY'), to_date('03/09/2017', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh13;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    14, 'Leroy', TABPRENOMS_T('Alice', 'J'), null, '39 rue de Blin', '+33-700-555-811', 'seano@verizon.fr', to_date('01/02/1976', 'DD/MM/YYYY'), to_date('07/11/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh14;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    15, 'Roux', TABPRENOMS_T('Liam', 'L'), null, '40 place Breton', '+33-765-556-770', 'dexter@yahoo.fr', to_date('08/01/1993', 'DD/MM/YYYY'), to_date('18/11/2018', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh15;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    16, 'David', TABPRENOMS_T('Lina', 'L'), null, '41 place Fernandez', '+33-655-529-040', 'fmerges@hotmail.fr', to_date('14/02/1984', 'DD/MM/YYYY'), to_date('06/05/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh16;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    17, 'Bertrand', TABPRENOMS_T('Chloé', 'M'), null, '42 chemin Perez', '+33-775-556-489', 'tedrlord@outlook.fr', to_date('20/02/1989', 'DD/MM/YYYY'), to_date('27/12/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh17;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    18, 'Morel', TABPRENOMS_T('Noah', 'A'), null, '43 chemin de Godard', '+33-700-555-252', 'gbacon@yahoo.fr', to_date('19/08/1981', 'DD/MM/YYYY'), to_date('10/08/2020', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh18;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    19, 'Fournier', TABPRENOMS_T('Ethan', 'P'), null, '44 rue de Duval', '+33-700-555-964', 'seanq@yahoo.fr', to_date('13/09/1992', 'DD/MM/YYYY'), to_date('16/11/2018', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh19;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    20, 'Girard', TABPRENOMS_T('Paul', 'P'), null, '45 rue de Etienne', '+33-655-543-488', 'dkeeler@verizon.fr', to_date('06/12/1990', 'DD/MM/YYYY'), to_date('24/05/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh20;
    

end;
/