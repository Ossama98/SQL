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

CREATE OR REPLACE TYPE TABEXEMPLAIRES_T AS TABLE OF REF EXEMPLAIRE_T
/

CREATE OR REPLACE TYPE BIBLIOTHEQUE_T AS OBJECT(
ID                          NUMBER(4),
REGION                      VARCHAR(50),
EXEMPLAIRES                 TABEXEMPLAIRES_T,
ADDRESSE                    VARCHAR(50),
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
------------------ Création des tables -----------------------------------------
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

-------------------- Création des indexes---------------------------------------
ALTER TABLE TABLE_REF_BIBLIOTHEQUE 
	ADD (SCOPE FOR (column_value) IS BIBLIOTHEQUE_O);

ALTER TABLE TABLE_REF_AUTEURS 
	ADD (SCOPE FOR (column_value) IS AUTEUR_O);

-- Indexes EMPRUNT
CREATE INDEX IDX_UNIQUE_EMPRUNT_DATE_START ON EMPRUNT_O(DATE_START);
CREATE INDEX IDX_UNIQUE_EMPRUNT_DATE_END ON EMPRUNT_O(DATE_END);

--Indexes ADHERENT
CREATE INDEX IDX_UNIQUE_ADHERENT_NOM ON ADHERENT_O(NOM);
CREATE INDEX IDX_UNIQUE_ADHERENT_VILLE ON ADHERENT_O(VILLE);
CREATE INDEX IDX_BIBLIOTHEQUE_NESTED_TABLE_ID ON TABLE_REF_BIBLIOTHEQUE(NESTED_TABLE_ID, COLUMN_VALUE);

--INDEXES CATALOGUE
CREATE INDEX IDX_CATALOGUE_NESTED_TABLE_ID ON TABLE_REF_AUTEURS(NESTED_TABLE_ID, COLUMN_VALUE);

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

refCat1 REF CATALOGUE_T;
refCat2 REF CATALOGUE_T;
refCat3 REF CATALOGUE_T;
refCat4 REF CATALOGUE_T;
refCat5 REF CATALOGUE_T;
refCat6 REF CATALOGUE_T;
refCat7 REF CATALOGUE_T;
refCat8 REF CATALOGUE_T;
refCat9 REF CATALOGUE_T;
refCat10 REF CATALOGUE_T;

refExm1 REF EXEMPLAIRE_T;
refExm2 REF EXEMPLAIRE_T;
refExm3 REF EXEMPLAIRE_T;
refExm4 REF EXEMPLAIRE_T;
refExm5 REF EXEMPLAIRE_T;
refExm6 REF EXEMPLAIRE_T;
refExm7 REF EXEMPLAIRE_T;
refExm8 REF EXEMPLAIRE_T;
refExm9 REF EXEMPLAIRE_T;
refExm10 REF EXEMPLAIRE_T;

refAut1 REF AUTEUR_T;
refAut2 REF AUTEUR_T;
refAut3 REF AUTEUR_T;
refAut4 REF AUTEUR_T;
refAut5 REF AUTEUR_T;
refAut6 REF AUTEUR_T;
refAut7 REF AUTEUR_T;

refBiblio1 REF BIBLIOTHEQUE_T;
refBiblio2 REF BIBLIOTHEQUE_T;
refBiblio3 REF BIBLIOTHEQUE_T;
refBiblio4 REF BIBLIOTHEQUE_T;
refBiblio5 REF BIBLIOTHEQUE_T;
refBiblio6 REF BIBLIOTHEQUE_T;
refBiblio7 REF BIBLIOTHEQUE_T;
refBiblio8 REF BIBLIOTHEQUE_T;
refBiblio9 REF BIBLIOTHEQUE_T;
refBiblio10 REF BIBLIOTHEQUE_T;

BEGIN
    
---------------------------------CATALOGUE----------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CATALOGUE_O ca VALUES (
    CATALOGUE_T(1,'LE PETIT PRINCE',to_date('06/04/1943','DD/MM/YYYY'),'Gallimard',TAB_REF_AUTEURS_T(refAut1),null))
    returning ref(ca) into refCat1;
    
INSERT INTO CATALOGUE_O ca VALUES (
    CATALOGUE_T(2,'LIVRE2',to_date('19/05/1998','DD/MM/YYYY'),'MAISON2',TAB_REF_AUTEURS_T(refAut2),null))
    returning ref(ca) into refCat2;    
  
INSERT INTO CATALOGUE_O ca VALUES (
    CATALOGUE_T(3,'LIVRE3',to_date('18/03/1997','DD/MM/YYYY'),'MAISON3',TAB_REF_AUTEURS_T(refAut3),null))
    returning ref(ca) into refCat3;        
    
INSERT INTO CATALOGUE_O ca VALUES (
    CATALOGUE_T(4,'LIVRE4',to_date('15/03/1999','DD/MM/YYYY'),'MAISON4',TAB_REF_AUTEURS_T(refAut4),null))
    returning ref(ca) into refCat4;
    
INSERT INTO CATALOGUE_O ca VALUES (
    CATALOGUE_T(5,'LIVRE5',to_date('07/07/2000','DD/MM/YYYY'),'MAISON5',TAB_REF_AUTEURS_T(refAut5),null))
    returning ref(ca) into refCat5;      
 
INSERT INTO CATALOGUE_O ca VALUES (
    CATALOGUE_T(6,'LIVRE5',to_date('09/01/1997','DD/MM/YYYY'),'MAISON6',TAB_REF_AUTEURS_T(refAut6),null))
    returning ref(ca) into refCat6;      
 
INSERT INTO CATALOGUE_O ca VALUES (
    CATALOGUE_T(7,'LIVRE7',to_date('12/11/1962','DD/MM/YYYY'),'MAISON7',TAB_REF_AUTEURS_T(refAut7),null))
    returning ref(ca) into refCat7;          

INSERT INTO CATALOGUE_O ca VALUES (
    CATALOGUE_T(8,'LIVRE8',to_date('01/12/1968','DD/MM/YYYY'),'MAISON8',TAB_REF_AUTEURS_T(refAut1, refAut2),null))
    returning ref(ca) into refCat8;      

INSERT INTO CATALOGUE_O ca VALUES (
    CATALOGUE_T(9,'LIVRE9',to_date('17/07/2000','DD/MM/YYYY'),'MAISON9',TAB_REF_AUTEURS_T(refAut7, refAut3),null))
    returning ref(ca) into refCat9;      

INSERT INTO CATALOGUE_O ca VALUES (
    CATALOGUE_T(10,'LIVRE10',to_date('02/06/1995','DD/MM/YYYY'),'MAISON10',TAB_REF_AUTEURS_T(refAut4, refAut7),null))
    returning ref(ca) into refCat10;
    
---------------------------AUTTEUR------------------------------------------------------------------------------------------------------------------------------------------------------
    
INSERT INTO AUTEUR_O ad VALUES (
            AUTEUR_T(
    1, 'GIRARD', TABPRENOMS_T('Paul', 'P'), to_date('06/12/1990', 'DD/MM/YYYY'), to_date('24/05/2019',  'DD-MM-YYYY'), 'FRANCAIS', 'Nice', null
    ))
    returning ref(ad) into refAut1;
    
    INSERT INTO AUTEUR_O ad VALUES (
            AUTEUR_T(
    2, 'GUILLOU', TABPRENOMS_T('Pierre', 'Pépé'), to_date('07/12/1999', 'DD/MM/YYYY'), to_date('24/12/2010',  'DD-MM-YYYY'), 'HONGROIS', 'Boston', null
    ))
    returning ref(ad) into refAut2;
    
    INSERT INTO AUTEUR_O ad VALUES (
            AUTEUR_T(
    3, 'JACOB', TABPRENOMS_T('Robin', 'Piedro'), to_date('23/10/1999', 'DD/MM/YYYY'), to_date('24/09/2018',  'DD-MM-YYYY'), 'JAPONAIS', 'Londre', null
    ))
    returning ref(ad) into refAut3;

INSERT INTO AUTEUR_O ad VALUES (
            AUTEUR_T(
    4, 'NOUILLE', TABPRENOMS_T('Crabi', 'Poulet'), to_date('06/12/2000', 'DD/MM/YYYY'), to_date('24/06/2019',  'DD-MM-YYYY'), 'FRANCAIS', 'Nice', null
    ))
    returning ref(ad) into refAut4;

INSERT INTO AUTEUR_O ad VALUES (
            AUTEUR_T(
    5, 'UNDEAD', TABPRENOMS_T('Jacques', 'P'), to_date('29/04/1899', 'DD/MM/YYYY'), to_date('29/04/1999', 'DD/MM/YYYY'), 'FRANCAIS', 'Nice', null
    ))
    returning ref(ad) into refAut5;

INSERT INTO AUTEUR_O ad VALUES (
            AUTEUR_T(
    6, 'LAGALLY', TABPRENOMS_T('Jacqueline', 'Micheline'), to_date('06/12/1990', 'DD/MM/YYYY'), null, 'RUSSE', 'Rostov-sur-le-Don', null
    ))
    returning ref(ad) into refAut6;


INSERT INTO AUTEUR_O ad VALUES (
            AUTEUR_T(
    7, 'KOUNA', TABPRENOMS_T('Boson', 'Odette'), to_date('15/03/0001', 'DD/MM/YYYY'), null, 'GRECQUE', 'Athena s Temple', null
    ))
    returning ref(ad) into refAut7;
    
---------------------- EXAMPLAIRES ------------------------------------------------------------------------------------------------------------------------------------------
    
INSERT INTO EXEMPLAIRE_O ex VALUES (
            EXEMPLAIRE_T(
    1, refCat1
    ))
    returning ref(ex) into refExm1;
    

INSERT INTO EXEMPLAIRE_O ex VALUES (
            EXEMPLAIRE_T(
    2, refCat2
    ))
    returning ref(ex) into refExm2;
    

INSERT INTO EXEMPLAIRE_O ex VALUES (
            EXEMPLAIRE_T(
    3, refCat3
    ))
    returning ref(ex) into refExm3;
    

INSERT INTO EXEMPLAIRE_O ex VALUES (
            EXEMPLAIRE_T(
    4, refCat4
    ))
    returning ref(ex) into refExm4;
    

INSERT INTO EXEMPLAIRE_O ex VALUES (
            EXEMPLAIRE_T(
    5, refCat5
    ))
    returning ref(ex) into refExm5;
    

INSERT INTO EXEMPLAIRE_O ex VALUES (
            EXEMPLAIRE_T(
    6, refCat6
    ))
    returning ref(ex) into refExm6;
    

INSERT INTO EXEMPLAIRE_O ex VALUES (
            EXEMPLAIRE_T(
    7, refCat7
    ))
    returning ref(ex) into refExm7;
    

INSERT INTO EXEMPLAIRE_O ex VALUES (
            EXEMPLAIRE_T(
    8, refCat8
    ))
    returning ref(ex) into refExm8;
    

INSERT INTO EXEMPLAIRE_O ex VALUES (
            EXEMPLAIRE_T(
    9, refCat9
    ))
    returning ref(ex) into refExm9;
    

INSERT INTO EXEMPLAIRE_O ex VALUES (
            EXEMPLAIRE_T(
    10, refCat10
    ))
    returning ref(ex) into refExm10;

---------------------------BIBLIOTHEQUE------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO BIBLIOTHEQUE_O el VALUES (
            BIBLIOTHEQUE_T(
    1, 'Ile-de-France', TABEXEMPLAIRES_T(refExm6, refExm8), '65  Faubourg Saint Honoré', 'PARIS'
    ))
    returning ref(el) into refBiblio1;
    
    INSERT INTO BIBLIOTHEQUE_O el VALUES (
            BIBLIOTHEQUE_T(
    2, 'Corse', TABEXEMPLAIRES_T(refExm3), '107  Rue du Limas', 'BASTIA'
    ))
    returning ref(el) into refBiblio2;


INSERT INTO BIBLIOTHEQUE_O el VALUES (
            BIBLIOTHEQUE_T(
    3, 'Nord-Pas-de-Calais', TABEXEMPLAIRES_T(refExm1), '54  rue Cazade', 'DUNKERQUE'
    ))
    returning ref(el) into refBiblio3;


INSERT INTO BIBLIOTHEQUE_O el VALUES (
            BIBLIOTHEQUE_T(
    4, 'Provence-Alpes-Côte d Azur', TABEXEMPLAIRES_T(refExm2), '65  cours Franklin Roosevelt', 'MARSEILLE'
    ))
    returning ref(el) into refBiblio4;


INSERT INTO BIBLIOTHEQUE_O el VALUES (
            BIBLIOTHEQUE_T(
    5, 'Rhône-Alpes', TABEXEMPLAIRES_T(refExm10, refExm9), '46  rue Gustave Eiffel', 'ROANNE'
    ))
    returning ref(el) into refBiblio5;
    
    INSERT INTO BIBLIOTHEQUE_O el VALUES (
            BIBLIOTHEQUE_T(
    6, 'Île-de-France', TABEXEMPLAIRES_T(refExm1, refExm2), '26  rue de Penthièvre', 'PONTOISE'
    ))
    returning ref(el) into refBiblio6;

INSERT INTO BIBLIOTHEQUE_O el VALUES (
            BIBLIOTHEQUE_T(
    7, 'Lorraine', TABEXEMPLAIRES_T(refExm4, refExm3), '33  boulevard Gustave Eiffel', 'VERDUN'
    ))
    returning ref(el) into refBiblio7;

INSERT INTO BIBLIOTHEQUE_O el VALUES (
            BIBLIOTHEQUE_T(
    8, 'Provence-Alpes-Côte d Azur', TABEXEMPLAIRES_T(refExm5, refExm6), '99  rue Reine Elisabeth', 'MENTON'
    ))
    returning ref(el) into refBiblio8;

INSERT INTO BIBLIOTHEQUE_O el VALUES (
            BIBLIOTHEQUE_T(
    9, 'Île-de-France', TABEXEMPLAIRES_T(refExm7, refExm8), '63  Square de la Couronne', 'PARIS'
    ))
    returning ref(el) into refBiblio9;

INSERT INTO BIBLIOTHEQUE_O el VALUES (
            BIBLIOTHEQUE_T(
    10, 'Nord-Pas-de-Calais', TABEXEMPLAIRES_T(refExm9), '32  Rue Hubert de Lisle', 'LOOS'
    ))
    returning ref(el) into refBiblio10;

-------------------------------------------------------------------------ADHERENT----------------------------------------------------------------------------
INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    1, 'Martin', TABPRENOMS_T('Gabriel', 'A'), refBiblio1, '26 boulevard Renaud', '+33-655-537-820', 'punkis@icloud.fr', to_date('11/02/1983', 'DD/MM/YYYY'), to_date('08/11/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh1;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    2, 'Bernard', TABPRENOMS_T('Léo', 'B'), refBiblio2, '27 rue Barbe', '+33-735-554-648', 'skoch@yahoo.fr', to_date('18/02/1973', 'DD/MM/YYYY'), to_date('14/06/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh2;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    3, 'Thomas', TABPRENOMS_T('Raphaël', 'C'), refBiblio3, '28 avenue de Martins', '+33-655-544-986', 'mrobshaw@live.fr', to_date('21/04/1988', 'DD/MM/YYYY'), to_date('11/01/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh3;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    4, 'Petit', TABPRENOMS_T('Arthur', 'D'), refBiblio4, '29 place Charles', '+33-655-582-035', 'geekgrl@outlook.fr', to_date('23/05/1967', 'DD/MM/YYYY'), to_date('04/08/2020', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh4;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    5, 'Robert', TABPRENOMS_T('Louis', 'E'), refBiblio5, '30 impasse Muller', '+33-775-557-450', 'malin@msn.fr', to_date('17/10/1984', 'DD/MM/YYYY'), to_date('28/06/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh5;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    6, 'Richard', TABPRENOMS_T('Emma', 'F'), refBiblio6, '31 rue Lamy', '+33-785-550-994', 'hmbrand@sbcglobal.fr', to_date('25/08/1967', 'DD/MM/YYYY'), to_date('09/12/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh6;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    7, 'Durand', TABPRENOMS_T('Jade', 'E'), refBiblio7, '32 rue Roy', '+33-655-552-115', 'zeitlin@hotmail.fr', to_date('26/01/1972', 'DD/MM/YYYY'), to_date('21/10/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh7;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    8, 'Dubois', TABPRENOMS_T('Louise', 'R'), refBiblio8, '33 place Roger', '+33-655-584-492', 'lamky@gmail.fr', to_date('02/06/2001', 'DD/MM/YYYY'), to_date('01/04/2017', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh8;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    9, 'Moreau', TABPRENOMS_T('Lucas', 'R'), refBiblio9, '34 avenue Peron', '+33-700-555-126', 'bryanw@live.fr', to_date('15/05/1994', 'DD/MM/YYYY'), to_date('26/06/2017', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh9;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    10, 'Laurent', TABPRENOMS_T('Adam', 'R'), refBiblio10, '35 avenue Maurice', '+33-700-555-643', 'helger@att.fr', to_date('07/03/1989', 'DD/MM/YYYY'), to_date('15/04/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh10;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    11, 'Simon', TABPRENOMS_T('Maël', 'M'), refBiblio1, '36 impasse Blanc', '+33-700-555-172', 'gator@msn.fr', to_date('27/02/1970', 'DD/MM/YYYY'), to_date('20/07/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh11;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    12, 'Michel', TABPRENOMS_T('Jules', 'J'), refBiblio2, '37 place Lemaire', '+33-655-531-855', 'psharpe@verizon.fr', to_date('05/04/1966', 'DD/MM/YYYY'), to_date('23/12/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh12;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    13, 'Lefebvre', TABPRENOMS_T('Hugo', 'J'), refBiblio3, '38 rue Simon', '+33-700-555-300', 'fangorn@mac.fr', to_date('10/04/1971', 'DD/MM/YYYY'), to_date('03/09/2017', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh13;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    14, 'Leroy', TABPRENOMS_T('Alice', 'J'), refBiblio4, '39 rue de Blin', '+33-700-555-811', 'seano@verizon.fr', to_date('01/02/1976', 'DD/MM/YYYY'), to_date('07/11/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh14;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    15, 'Roux', TABPRENOMS_T('Liam', 'L'), refBiblio5, '40 place Breton', '+33-765-556-770', 'dexter@yahoo.fr', to_date('08/01/1993', 'DD/MM/YYYY'), to_date('18/11/2018', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh15;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    16, 'David', TABPRENOMS_T('Lina', 'L'), refBiblio6, '41 place Fernandez', '+33-655-529-040', 'fmerges@hotmail.fr', to_date('14/02/1984', 'DD/MM/YYYY'), to_date('06/05/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh16;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    17, 'Bertrand', TABPRENOMS_T('Chloé', 'M'), refBiblio7, '42 chemin Perez', '+33-775-556-489', 'tedrlord@outlook.fr', to_date('20/02/1989', 'DD/MM/YYYY'), to_date('27/12/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh17;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    18, 'Morel', TABPRENOMS_T('Noah', 'A'), refBiblio8, '43 chemin de Godard', '+33-700-555-252', 'gbacon@yahoo.fr', to_date('19/08/1981', 'DD/MM/YYYY'), to_date('10/08/2020', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh18;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    19, 'Fournier', TABPRENOMS_T('Ethan', 'P'), refBiblio9, '44 rue de Duval', '+33-700-555-964', 'seanq@yahoo.fr', to_date('13/09/1992', 'DD/MM/YYYY'), to_date('16/11/2018', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh19;
    

INSERT INTO ADHERENT_O ad VALUES (
            ADHERENT_T(
    20, 'Girard', TABPRENOMS_T('Paul', 'P'), refBiblio10, '45 rue de Etienne', '+33-655-543-488', 'dkeeler@verizon.fr', to_date('06/12/1990', 'DD/MM/YYYY'), to_date('24/05/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    returning ref(ad) into refAdh20;
    
---------------------------------------------------------------------------------EMPRUNT----- ---------------------------------------------------------------------------  
INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    1, refAdh1, to_date('21/01/2020', 'DD-MM-YYYY'), to_date('21/02/2020', 'DD-MM-YYYY'), to_date('15/02/2020', 'DD-MM-YYYY'), refExm1
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    2, refAdh2, to_date('19/04/2020', 'DD-MM-YYYY'), to_date('19/05/2020', 'DD-MM-YYYY'), to_date('13/05/2020', 'DD-MM-YYYY'), refExm2
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    3, refAdh3, to_date('05/02/2020', 'DD-MM-YYYY'), to_date('05/03/2020', 'DD-MM-YYYY'), to_date('01/03/2020', 'DD-MM-YYYY'), refExm3
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    4, refAdh4, to_date('30/03/2020', 'DD-MM-YYYY'), to_date('30/04/2020', 'DD-MM-YYYY'), to_date('25/04/2020', 'DD-MM-YYYY'), refExm4
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    5, refAdh5, to_date('06/08/2020', 'DD-MM-YYYY'), to_date('06/09/2020', 'DD-MM-YYYY'), to_date('01/09/2020', 'DD-MM-YYYY'), refExm5
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    6, refAdh6, to_date('04/04/2020', 'DD-MM-YYYY'), to_date('04/05/2020', 'DD-MM-YYYY'), to_date('01/05/2020', 'DD-MM-YYYY'), refExm6
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    7, refAdh7, to_date('06/08/2020', 'DD-MM-YYYY'), to_date('06/09/2020', 'DD-MM-YYYY'), to_date('01/09/2020', 'DD-MM-YYYY'), refExm7
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    8, refAdh8, to_date('26/01/2020', 'DD-MM-YYYY'), to_date('26/02/2020', 'DD-MM-YYYY'), to_date('19/02/2020', 'DD-MM-YYYY'), refExm8
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    9, refAdh9, to_date('26/08/2020', 'DD-MM-YYYY'), to_date('26/09/2020', 'DD-MM-YYYY'), to_date('23/09/2020', 'DD-MM-YYYY'), refExm9
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    10, refAdh10, to_date('10/06/2020', 'DD-MM-YYYY'), to_date('10/07/2020', 'DD-MM-YYYY'), to_date('05/07/2020', 'DD-MM-YYYY'), refExm10
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    11, refAdh11, to_date('14/05/2020', 'DD-MM-YYYY'), to_date('14/06/2020', 'DD-MM-YYYY'), to_date('10/06/2020', 'DD-MM-YYYY'), refExm1
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    12, refAdh12, to_date('11/01/2020', 'DD-MM-YYYY'), to_date('11/08/2020', 'DD-MM-YYYY'), to_date('01/08/2020', 'DD-MM-YYYY'), refExm2
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    13, refAdh13, to_date('23/04/2020', 'DD-MM-YYYY'), to_date('23/05/2020', 'DD-MM-YYYY'), to_date('01/05/2020', 'DD-MM-YYYY'), refExm3
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    14, refAdh14, to_date('16/01/2020', 'DD-MM-YYYY'), to_date('16/02/2020', 'DD-MM-YYYY'), to_date('01/02/2020', 'DD-MM-YYYY'), refExm4
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    15, refAdh15, to_date('07/06/2020', 'DD-MM-YYYY'), to_date('07/07/2020', 'DD-MM-YYYY'), to_date('01/07/2020', 'DD-MM-YYYY'), refExm5
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    16, refAdh16, to_date('23/06/2020', 'DD-MM-YYYY'), to_date('23/07/2020', 'DD-MM-YYYY'), null, refExm5
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    17, refAdh17, to_date('20/08/2020', 'DD-MM-YYYY'), to_date('20/09/2020', 'DD-MM-YYYY'), null, refExm6
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    18, refAdh18, to_date('09/05/2020', 'DD-MM-YYYY'), to_date('09/06/2020', 'DD-MM-YYYY'), null, refExm7
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    19, refAdh19, to_date('23/04/2020', 'DD-MM-YYYY'), to_date('23/07/2020', 'DD-MM-YYYY'), null, refExm8
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    20, refAdh20, to_date('05/05/2020', 'DD-MM-YYYY'), to_date('05/06/2020', 'DD-MM-YYYY'), null, refExm9
    ));
END;
/
