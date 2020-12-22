DROP TABLE  CATALOGUE_O CASCADE CONSTRAINTS;
DROP TABLE  EXEMPLAIRE_O CASCADE CONSTRAINTS;
DROP TABLE  AUTEUR_O CASCADE CONSTRAINTS;
DROP TABLE  BIBLIOTHEQUE_O CASCADE CONSTRAINTS;
DROP TABLE  EMPRUNT_O CASCADE CONSTRAINTS;
DROP TABLE  ADHERENT_O CASCADE CONSTRAINTS;

DROP TYPE   AUTEUR_T FORCE;
DROP TYPE   TAB_REF_AUTEURS_T FORCE ;
DROP TYPE   CATALOGUE_T FORCE;
DROP TYPE   EXEMPLAIRE_T FORCE;
DROP TYPE   TAB_REF_EXEMPLAIRES_T FORCE;
DROP TYPE   BIBLIOTHEQUE_T FORCE;
DROP TYPE   LIST_PRENOMS_T FORCE;
DROP TYPE   ADHERENT_T FORCE;
DROP TYPE   TAB_REF_BIBLIOTHEQUES_T FORCE;
DROP TYPE   EMPRUNT_T FORCE;

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
DESCRIPTION         CLOB,
ORDER MEMBER FUNCTION COMPANNEEEDITION(CA CATALOGUE_T) RETURN NUMBER,  -- comparer avec ANNEE_EDITION décroissant
MEMBER FUNCTION CONSULTERAUTEURS RETURN TAB_REF_AUTEURS_T
);
/
CREATE OR REPLACE TYPE BODY CATALOGUE_T AS
    ORDER MEMBER FUNCTION COMPANNEEEDITION(CA CATALOGUE_T) RETURN NUMBER IS
    BEGIN
        IF ANNEE_EDITION < CA.ANNEE_EDITION THEN
           RETURN 1;  --SI ON VEUT COMPARER PAR ORDRE CROISSANT RETURN -1
        ELSIF ANNEE_EDITION > CA.ANNEE_EDITION THEN
            RETURN -1;   --SI ON VEUT COMPARER PAR ORDRE CROISSANT RETURN 1
        ELSE
            RETURN 0;
        END IF;
    END;
    
    MEMBER FUNCTION CONSULTERAUTEURS RETURN TAB_REF_AUTEURS_T IS
    BEGIN
        RETURN REF_AUTEURS;
    END;
END;
/
    
    
CREATE OR REPLACE TYPE EXEMPLAIRE_T AS OBJECT(
EXNO                  NUMBER(4),
REF_CATALOGUE         REF CATALOGUE_T,
ORDER MEMBER FUNCTION COMPID(E EXEMPLAIRE_T) RETURN NUMBER -- comparer avec ID croissant
);
/
CREATE OR REPLACE TYPE BODY EXEMPLAIRE_T AS
    ORDER MEMBER FUNCTION COMPID(E EXEMPLAIRE_T) RETURN NUMBER IS
    BEGIN
        IF EXNO < E.EXNO THEN
           RETURN -1 ;  --SI ON VEUT COMPARER PAR ORDRE DÉCROISSANT RETURN 1
        ELSIF EXNO > E.EXNO THEN
            RETURN 1;   --SI ON VEUT COMPARER PAR ORDRE DÉCROISSANT RETURN -1
        ELSE
            RETURN 0;
        END IF;
    END;
END;
/


CREATE OR REPLACE TYPE TAB_REF_EXEMPLAIRES_T AS TABLE OF REF EXEMPLAIRE_T
/

CREATE OR REPLACE TYPE BIBLIOTHEQUE_T AS OBJECT(
ID                          NUMBER(4),
NOM                         VARCHAR(50),
REGION                      VARCHAR(50),
REF_EXEMPLAIRES             TAB_REF_EXEMPLAIRES_T,
ADDRESSE                    VARCHAR(50),
VILLE                       VARCHAR(20),
MAP MEMBER FUNCTION COMPREGIONVILLE RETURN VARCHAR2, -- comparer avec région||ville
MEMBER PROCEDURE AJOUTEXEMPLAIRE(EXEMPLAIRE IN EXEMPLAIRE_T)
);
/
CREATE OR REPLACE TYPE BODY BIBLIOTHEQUE_T AS 
    MAP MEMBER FUNCTION COMPREGIONVILLE RETURN VARCHAR2 IS
    BEGIN
        RETURN REGION||VILLE;
    END;
    
    MEMBER PROCEDURE AJOUTEXEMPLAIRE(EXEMPLAIRE IN EXEMPLAIRE_T) IS
    BEGIN
        NULL;
    END;

END;
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
MAP MEMBER FUNCTION COMPDATEEND RETURN DATE, -- comparer avec DATE_END croissant
MEMBER PROCEDURE PROLONGERDATEEND(NBJOURS IN NUMBER),
MEMBER FUNCTION TESTRETARD RETURN NUMBER
);
/

CREATE OR REPLACE TYPE BODY EMPRUNT_T AS 
    MAP MEMBER FUNCTION COMPDATEEND RETURN DATE IS
    BEGIN
        RETURN DATE_END;
    END;
    
    MEMBER PROCEDURE PROLONGERDATEEND(NBJOURS IN NUMBER) IS
    BEGIN
        DATE_END := DATE_END + NBJOURS;
    END;
     
     MEMBER FUNCTION TESTRETARD RETURN NUMBER IS
     BEGIN
        IF (DATE_END < CURRENT_DATE) AND (DATE_RETOUR IS NULL) THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
     END;

END;
/

CREATE OR REPLACE TYPE LIST_PRENOMS_T AS VARRAY(4) OF VARCHAR2(40);
/

CREATE OR REPLACE TYPE TAB_REF_BIBLIOTHEQUES_T AS TABLE OF REF BIBLIOTHEQUE_T
/

CREATE OR REPLACE TYPE ADHERENT_T AS OBJECT(
NUMERO_ADHERENT            NUMBER(4),
NOM                        VARCHAR2(20),
PRENOMS                    LIST_PRENOMS_T,
REF_BIBLIOTHEQUES          TAB_REF_BIBLIOTHEQUES_T,
ADRESSE                    VARCHAR2(20),
PHONE                      VARCHAR2(20),
EMAIL                      VARCHAR2(20),
DATE_DE_NAISSANCE          DATE,
DATE_D_ADHESION            DATE,
VILLE                      VARCHAR2(20),
MAP MEMBER FUNCTION COMPNOMPRENOMSVILLE RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY ADHERENT_T AS 
    MAP MEMBER FUNCTION COMPNOMPRENOMSVILLE RETURN VARCHAR2 IS
    BEGIN
        RETURN NOM||PRENOMS.FIRST||VILLE;
    END;
END;
/

CREATE OR REPLACE TYPE AUTEUR_T AS OBJECT(
ID                          NUMBER(4),
NOM                         VARCHAR2(20),
PRENOMS                     LIST_PRENOMS_T,
DATE_DE_NAISSANCE           DATE,
DATE_DE_DECES               DATE,
NATIONALITE                 VARCHAR(20),
VILLE                       VARCHAR(20),
BIOGRAPHIE                  CLOB,
MAP MEMBER FUNCTION COMPNOMPRENOMNAISSANCE RETURN VARCHAR2, -- comparer avec NOM||PREMIER PRENOM||DATE_DE_NAISSANCE
MEMBER FUNCTION GETAUTEUR RETURN AUTEUR_T
);
/
CREATE OR REPLACE TYPE BODY AUTEUR_T IS 
    MEMBER FUNCTION GETAUTEUR RETURN AUTEUR_T IS
    BEGIN
        RETURN SELF;
    END;
    
    MAP MEMBER FUNCTION COMPNOMPRENOMNAISSANCE RETURN VARCHAR2 IS
    BEGIN
        RETURN NOM||PRENOMS(1)||DATE_DE_NAISSANCE;
    END;
END;
/

------------------ Création des tables -----------------------------------------
CREATE TABLE CATALOGUE_O OF CATALOGUE_T(
CONSTRAINT PK_CATALOGUE_O_CATNO PRIMARY KEY(CATNO),
CONSTRAINT NNL_CATALOGUE_O_TITRE TITRE NOT NULL 
)
NESTED TABLE REF_AUTEURS STORE AS TABLE_REF_AUTEURS ,
LOB(DESCRIPTION) STORE AS STORE_LOB_DESCRIPTIONS 
/

CREATE TABLE EXEMPLAIRE_O OF EXEMPLAIRE_T(
CONSTRAINT PK_EXEMPLAIRE_O_EXNO PRIMARY KEY(EXNO)
)
/

CREATE TABLE AUTEUR_O OF AUTEUR_T(
    CONSTRAINT PK_AUTEUR_O_ID PRIMARY KEY(ID),
    CONSTRAINT NNL_AUTEUR_O_NOM NOM NOT NULL,
    CONSTRAINT CHK_O_AUTEUR_NOM CHECK(NOM=UPPER(NOM)),
    CONSTRAINT NNL_AUTEUR_O_PRENOMS PRENOMS NOT NULL,
    CONSTRAINT NNL_AUTEUR_O_DATE_DE_NAISSANCE DATE_DE_NAISSANCE NOT NULL,
    CONSTRAINT NNL_AUTEUR_O_NATIONALITE NATIONALITE NOT NULL,
    CONSTRAINT NNL_AUTEUR_O_VILLE VILLE NOT NULL
)
LOB(BIOGRAPHIE) STORE AS STORELOBBIOGRAPHIE
/

CREATE TABLE BIBLIOTHEQUE_O OF BIBLIOTHEQUE_T(
    CONSTRAINT PK_BIBLIOTHEQUE_O_ID PRIMARY KEY(ID),
    CONSTRAINT NNL_BIBLIOTHEQUE_O_NOM NOM NOT NULL,
    CONSTRAINT NNL_BIBLIOTHEQUE_O_REGION REGION NOT NULL,
    CONSTRAINT NNL_BIBLIOTHEQUE_O_ADDRESSE ADDRESSE NOT NULL,
    CONSTRAINT NNL_BIBLIOTHEQUE_O_VILLE VILLE NOT NULL
)
NESTED TABLE REF_EXEMPLAIRES STORE AS TABLE_EXEMPLAIRES
/

CREATE TABLE EMPRUNT_O OF EMPRUNT_T(
    CONSTRAINT PK_EMPRUNT_O_ID PRIMARY KEY(ID),
    CONSTRAINT NNL_EMPRUNT_O_REF_ADHERENT REF_ADHERENT NOT NULL,
    CONSTRAINT NNL_EMPRUNT_O_DATE_START DATE_START NOT NULL,
    CONSTRAINT NNL_EMPRUNT_O_DATE_END DATE_END NOT NULL,
    CONSTRAINT NNL_EMPRUNT_O_REF_EXEMPLAIRE REF_EXEMPLAIRE NOT NULL,
    CONSTRAINT CHK_EMPRUNT_O_DATE_START_END CHECK(DATE_START<DATE_END)
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
NESTED TABLE REF_BIBLIOTHEQUES STORE AS TABLE_REF_BIBLIOTHEQUE
/

-------------------- Création des indexes ---------------------------------------
ALTER TABLE TABLE_REF_BIBLIOTHEQUE 
	ADD (SCOPE FOR (COLUMN_VALUE) IS BIBLIOTHEQUE_O);

ALTER TABLE TABLE_REF_AUTEURS 
	ADD (SCOPE FOR (COLUMN_VALUE) IS AUTEUR_O);

ALTER TABLE EXEMPLAIRE_O 
	ADD (SCOPE FOR (REF_CATALOGUE) IS CATALOGUE_O);

-- Indexes EMPRUNT
CREATE INDEX IDX_UNIQUE_EMPRUNT_DATE_START ON EMPRUNT_O(DATE_START);
CREATE INDEX IDX_UNIQUE_EMPRUNT_DATE_END ON EMPRUNT_O(DATE_END);

--Indexes ADHERENT
CREATE INDEX IDX_UNIQUE_ADHERENT_NOM ON ADHERENT_O(NOM);
CREATE INDEX IDX_UNIQUE_ADHERENT_VILLE ON ADHERENT_O(VILLE);
CREATE INDEX IDX_BIBLIOTHEQUE_NESTED_TABLE_ID ON TABLE_REF_BIBLIOTHEQUE(NESTED_TABLE_ID, COLUMN_VALUE);

--Indexes AUTEUR
CREATE INDEX IDX_UNIQUE_AUTEUR_NOM ON AUTEUR_O(NOM);
CREATE INDEX IDX_UNIQUE_AUTEUR_VILLE ON AUTEUR_O(VILLE);
CREATE INDEX IDX_UNIQUE_AUTEUR_NATIONALITE ON AUTEUR_O(NATIONALITE);

--INDEXES CATALOGUE
CREATE INDEX IDX_CATALOGUE_NESTED_TABLE_ID ON TABLE_REF_AUTEURS(NESTED_TABLE_ID, COLUMN_VALUE);
CREATE INDEX IDX_UNIQUE_TITRE ON CATALOGUE_O(TITRE);

--INDEXES BIBLIOTHEQUE
CREATE INDEX IDX_UNIQUE_BIBLIOTHEQUE_REGION ON BIBLIOTHEQUE_O(REGION);

--INDEXES EXEMPLAIRE
CREATE INDEX IDX_UNIQUE_EXEMPLAIRE_REF_CATALOGUE ON EXEMPLAIRE_O(REF_CATALOGUE);
 
-------------------- Insertion des adherents ---------------------------------------
DECLARE
REFADH1 REF ADHERENT_T;
REFADH2 REF ADHERENT_T;
REFADH3 REF ADHERENT_T;
REFADH4 REF ADHERENT_T;
REFADH5 REF ADHERENT_T;
REFADH6 REF ADHERENT_T;
REFADH7 REF ADHERENT_T;
REFADH8 REF ADHERENT_T;
REFADH9 REF ADHERENT_T;
REFADH10 REF ADHERENT_T;
REFADH11 REF ADHERENT_T;
REFADH12 REF ADHERENT_T;
REFADH13 REF ADHERENT_T;
REFADH14 REF ADHERENT_T;
REFADH15 REF ADHERENT_T;
REFADH16 REF ADHERENT_T;
REFADH17 REF ADHERENT_T;
REFADH18 REF ADHERENT_T;
REFADH19 REF ADHERENT_T;
REFADH20 REF ADHERENT_T;

REFCAT1 REF CATALOGUE_T;
REFCAT2 REF CATALOGUE_T;
REFCAT3 REF CATALOGUE_T;
REFCAT4 REF CATALOGUE_T;
REFCAT5 REF CATALOGUE_T;
REFCAT6 REF CATALOGUE_T;
REFCAT7 REF CATALOGUE_T;
REFCAT8 REF CATALOGUE_T;
REFCAT9 REF CATALOGUE_T;
REFCAT10 REF CATALOGUE_T;
REFCAT11 REF CATALOGUE_T;

REFEXM1 REF EXEMPLAIRE_T;
REFEXM2 REF EXEMPLAIRE_T;
REFEXM3 REF EXEMPLAIRE_T;
REFEXM4 REF EXEMPLAIRE_T;
REFEXM5 REF EXEMPLAIRE_T;
REFEXM6 REF EXEMPLAIRE_T;
REFEXM7 REF EXEMPLAIRE_T;
REFEXM8 REF EXEMPLAIRE_T;
REFEXM9 REF EXEMPLAIRE_T;
REFEXM10 REF EXEMPLAIRE_T;
REFEXM11 REF EXEMPLAIRE_T;

REFAUT1 REF AUTEUR_T;
REFAUT2 REF AUTEUR_T;
REFAUT3 REF AUTEUR_T;
REFAUT4 REF AUTEUR_T;
REFAUT5 REF AUTEUR_T;
REFAUT6 REF AUTEUR_T;
REFAUT7 REF AUTEUR_T;
REFAUT8 REF AUTEUR_T;

REFBIBLIO1 REF BIBLIOTHEQUE_T;
REFBIBLIO2 REF BIBLIOTHEQUE_T;
REFBIBLIO3 REF BIBLIOTHEQUE_T;
REFBIBLIO4 REF BIBLIOTHEQUE_T;
REFBIBLIO5 REF BIBLIOTHEQUE_T;
REFBIBLIO6 REF BIBLIOTHEQUE_T;
REFBIBLIO7 REF BIBLIOTHEQUE_T;
REFBIBLIO8 REF BIBLIOTHEQUE_T;
REFBIBLIO9 REF BIBLIOTHEQUE_T;
REFBIBLIO10 REF BIBLIOTHEQUE_T;

BEGIN
    
---------------------------------AUTEUR----------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO AUTEUR_O AD VALUES (
            AUTEUR_T(
    1, 'GIRARD', LIST_PRENOMS_T('Paul', 'P'), TO_DATE('06/12/1990', 'DD/MM/YYYY'), TO_DATE('24/05/2019',  'DD-MM-YYYY'), 'FRANCAIS', 'Nice', NULL
    ))
    RETURNING REF(AD) INTO REFAUT1;
    
    INSERT INTO AUTEUR_O AD VALUES (
            AUTEUR_T(
    2, 'GUILLOU', LIST_PRENOMS_T('Pierre', 'Pépé'), TO_DATE('07/12/1999', 'DD/MM/YYYY'), TO_DATE('24/12/2010',  'DD-MM-YYYY'), 'HONGROIS', 'Boston', NULL
    ))
    RETURNING REF(AD) INTO REFAUT2;
    
    INSERT INTO AUTEUR_O AD VALUES (
            AUTEUR_T(
    3, 'JACOB', LIST_PRENOMS_T('Robin', 'Piedro'), TO_DATE('23/10/1999', 'DD/MM/YYYY'), TO_DATE('24/09/2018',  'DD-MM-YYYY'), 'JAPONAIS', 'Londre', NULL
    ))
    RETURNING REF(AD) INTO REFAUT3;

INSERT INTO AUTEUR_O AD VALUES (
            AUTEUR_T(
    4, 'NOUILLE', LIST_PRENOMS_T('Crabi', 'Poulet'), TO_DATE('06/12/2000', 'DD/MM/YYYY'), TO_DATE('24/06/2019',  'DD-MM-YYYY'), 'FRANCAIS', 'Nice', NULL
    ))
    RETURNING REF(AD) INTO REFAUT4;

INSERT INTO AUTEUR_O AD VALUES (
            AUTEUR_T(
    5, 'UNDEAD', LIST_PRENOMS_T('Jacques', 'P'), TO_DATE('29/04/1899', 'DD/MM/YYYY'), TO_DATE('29/04/1999', 'DD/MM/YYYY'), 'FRANCAIS', 'Nice', NULL
    ))
    RETURNING REF(AD) INTO REFAUT5;

INSERT INTO AUTEUR_O AD VALUES (
            AUTEUR_T(
    6, 'LAGALLY', LIST_PRENOMS_T('Jacqueline', 'Micheline'), TO_DATE('06/12/1990', 'DD/MM/YYYY'), TO_DATE('14/02/1976', 'DD/MM/YYYY'), 'RUSSE', 'Rostov-sur-le-Don', NULL
    ))
    RETURNING REF(AD) INTO REFAUT6;


INSERT INTO AUTEUR_O AD VALUES (
            AUTEUR_T(
    7, 'KOUNA', LIST_PRENOMS_T('Boson', 'Odette'), TO_DATE('15/03/0001', 'DD/MM/YYYY'), TO_DATE('03/11/1955', 'DD/MM/YYYY'), 'GRECQUE', 'Athena s Temple', NULL
    ))
    RETURNING REF(AD) INTO REFAUT7;
INSERT INTO AUTEUR_O AD VALUES (
            AUTEUR_T(
    8, 'UNDEAD', LIST_PRENOMS_T('Jacques', 'P'), TO_DATE('28/04/1899', 'DD/MM/YYYY'), TO_DATE('29/04/1999', 'DD/MM/YYYY'), 'FRANCAIS', 'Nice', NULL
    ))
    RETURNING REF(AD) INTO REFAUT8;
    
---------------------------CATALOGUE------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CATALOGUE_O CA VALUES (
    CATALOGUE_T(1,'LE PETIT PRINCE',TO_DATE('06/04/1943','DD/MM/YYYY'),'Gallimard',TAB_REF_AUTEURS_T(REFAUT1),NULL))
    RETURNING REF(CA) INTO REFCAT1;
    
INSERT INTO CATALOGUE_O CA VALUES (
    CATALOGUE_T(2,'LIVRE2',TO_DATE('19/05/1998','DD/MM/YYYY'),'MAISON2',TAB_REF_AUTEURS_T(REFAUT2),NULL))
    RETURNING REF(CA) INTO REFCAT2;    
  
INSERT INTO CATALOGUE_O CA VALUES (
    CATALOGUE_T(3,'LIVRE3',TO_DATE('18/03/1997','DD/MM/YYYY'),'MAISON3',TAB_REF_AUTEURS_T(REFAUT3),NULL))
    RETURNING REF(CA) INTO REFCAT3;        
    
INSERT INTO CATALOGUE_O CA VALUES (
    CATALOGUE_T(4,'LIVRE4',TO_DATE('15/03/1999','DD/MM/YYYY'),'MAISON4',TAB_REF_AUTEURS_T(REFAUT4),NULL))
    RETURNING REF(CA) INTO REFCAT4;
    
INSERT INTO CATALOGUE_O CA VALUES (
    CATALOGUE_T(5,'LIVRE5',TO_DATE('07/07/2000','DD/MM/YYYY'),'MAISON5',TAB_REF_AUTEURS_T(REFAUT5),NULL))
    RETURNING REF(CA) INTO REFCAT5;      
 
INSERT INTO CATALOGUE_O CA VALUES (
    CATALOGUE_T(6,'LIVRE6',TO_DATE('09/01/1997','DD/MM/YYYY'),'MAISON6',TAB_REF_AUTEURS_T(REFAUT6),NULL))
    RETURNING REF(CA) INTO REFCAT6;      
 
INSERT INTO CATALOGUE_O CA VALUES (
    CATALOGUE_T(7,'LIVRE7',TO_DATE('12/11/1962','DD/MM/YYYY'),'MAISON7',TAB_REF_AUTEURS_T(REFAUT7),NULL))
    RETURNING REF(CA) INTO REFCAT7;          

INSERT INTO CATALOGUE_O CA VALUES (
    CATALOGUE_T(8,'LIVRE8',TO_DATE('01/12/1968','DD/MM/YYYY'),'MAISON8',TAB_REF_AUTEURS_T(REFAUT1, REFAUT2),NULL))
    RETURNING REF(CA) INTO REFCAT8;      

INSERT INTO CATALOGUE_O CA VALUES (
    CATALOGUE_T(9,'LIVRE9',TO_DATE('17/07/2000','DD/MM/YYYY'),'MAISON9',TAB_REF_AUTEURS_T(REFAUT7, REFAUT3),NULL))
    RETURNING REF(CA) INTO REFCAT9;      

INSERT INTO CATALOGUE_O CA VALUES (
    CATALOGUE_T(10,'LIVRE10',TO_DATE('02/06/1995','DD/MM/YYYY'),'MAISON10',TAB_REF_AUTEURS_T(REFAUT4, REFAUT7),NULL))
    RETURNING REF(CA) INTO REFCAT10;    
    
INSERT INTO CATALOGUE_O CA VALUES (
    CATALOGUE_T(11,'LIVRE11',TO_DATE('02/05/1998','DD/MM/YYYY'),'MAISON11',TAB_REF_AUTEURS_T(REFAUT2, REFAUT4),NULL))
    RETURNING REF(CA) INTO REFCAT11;   
    
---------------------- EXAMPLAIRES ------------------------------------------------------------------------------------------------------------------------------------------
    
INSERT INTO EXEMPLAIRE_O EX VALUES (
            EXEMPLAIRE_T(
    1, REFCAT1
    ))
    RETURNING REF(EX) INTO REFEXM1;
    

INSERT INTO EXEMPLAIRE_O EX VALUES (
            EXEMPLAIRE_T(
    2, REFCAT2
    ))
    RETURNING REF(EX) INTO REFEXM2;
    

INSERT INTO EXEMPLAIRE_O EX VALUES (
            EXEMPLAIRE_T(
    3, REFCAT3
    ))
    RETURNING REF(EX) INTO REFEXM3;
    

INSERT INTO EXEMPLAIRE_O EX VALUES (
            EXEMPLAIRE_T(
    4, REFCAT4
    ))
    RETURNING REF(EX) INTO REFEXM4;
    

INSERT INTO EXEMPLAIRE_O EX VALUES (
            EXEMPLAIRE_T(
    5, REFCAT5
    ))
    RETURNING REF(EX) INTO REFEXM5;
    

INSERT INTO EXEMPLAIRE_O EX VALUES (
            EXEMPLAIRE_T(
    6, REFCAT6
    ))
    RETURNING REF(EX) INTO REFEXM6;
    

INSERT INTO EXEMPLAIRE_O EX VALUES (
            EXEMPLAIRE_T(
    7, REFCAT7
    ))
    RETURNING REF(EX) INTO REFEXM7;
    

INSERT INTO EXEMPLAIRE_O EX VALUES (
            EXEMPLAIRE_T(
    8, REFCAT8
    ))
    RETURNING REF(EX) INTO REFEXM8;
    

INSERT INTO EXEMPLAIRE_O EX VALUES (
            EXEMPLAIRE_T(
    9, REFCAT9
    ))
    RETURNING REF(EX) INTO REFEXM9;
    

INSERT INTO EXEMPLAIRE_O EX VALUES (
            EXEMPLAIRE_T(
    10, REFCAT10
    ))
    RETURNING REF(EX) INTO REFEXM10;

INSERT INTO EXEMPLAIRE_O EX VALUES (
            EXEMPLAIRE_T(
    11, REFCAT11
    ))
    RETURNING REF(EX) INTO REFEXM11;
---------------------------BIBLIOTHEQUE------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO BIBLIOTHEQUE_O EL VALUES (
            BIBLIOTHEQUE_T(
    1,'BIBLIOTHEQUE_1', 'Île-de-France', TAB_REF_EXEMPLAIRES_T(REFEXM6, REFEXM8, REFEXM11), '65  Faubourg Saint Honoré', 'PARIS'
    ))
    RETURNING REF(EL) INTO REFBIBLIO1;
    
    INSERT INTO BIBLIOTHEQUE_O EL VALUES (
            BIBLIOTHEQUE_T(
    2,'BIBLIOTHEQUE_2', 'Corse', TAB_REF_EXEMPLAIRES_T(REFEXM3), '107  Rue du Limas', 'BASTIA'
    ))
    RETURNING REF(EL) INTO REFBIBLIO2;


INSERT INTO BIBLIOTHEQUE_O EL VALUES (
            BIBLIOTHEQUE_T(
    3,'BIBLIOTHEQUE_3', 'Nord-Pas-de-Calais', TAB_REF_EXEMPLAIRES_T(REFEXM1), '54  rue Cazade', 'DUNKERQUE'
    ))
    RETURNING REF(EL) INTO REFBIBLIO3;


INSERT INTO BIBLIOTHEQUE_O EL VALUES (
            BIBLIOTHEQUE_T(
    4,'BIBLIOTHEQUE_4', 'Provence-Alpes-Côte d Azur', TAB_REF_EXEMPLAIRES_T(REFEXM2), '65  cours Franklin Roosevelt', 'MARSEILLE'
    ))
    RETURNING REF(EL) INTO REFBIBLIO4;


INSERT INTO BIBLIOTHEQUE_O EL VALUES (
            BIBLIOTHEQUE_T(
    5,'BIBLIOTHEQUE_5', 'Rhône-Alpes', TAB_REF_EXEMPLAIRES_T(REFEXM10, REFEXM9), '46  rue Gustave Eiffel', 'ROANNE'
    ))
    RETURNING REF(EL) INTO REFBIBLIO5;
    
    INSERT INTO BIBLIOTHEQUE_O EL VALUES (
            BIBLIOTHEQUE_T(
    6,'BIBLIOTHEQUE_6', 'Île-de-France', TAB_REF_EXEMPLAIRES_T(REFEXM1, REFEXM2), '26  rue de Penthièvre', 'PONTOISE'
    ))
    RETURNING REF(EL) INTO REFBIBLIO6;

INSERT INTO BIBLIOTHEQUE_O EL VALUES (
            BIBLIOTHEQUE_T(
    7,'BIBLIOTHEQUE_7', 'Lorraine', TAB_REF_EXEMPLAIRES_T(REFEXM4, REFEXM3), '33  boulevard Gustave Eiffel', 'VERDUN'
    ))
    RETURNING REF(EL) INTO REFBIBLIO7;

INSERT INTO BIBLIOTHEQUE_O EL VALUES (
            BIBLIOTHEQUE_T(
    8,'BIBLIOTHEQUE_8', 'Provence-Alpes-Côte d Azur', TAB_REF_EXEMPLAIRES_T(REFEXM5, REFEXM6), '99  rue Reine Elisabeth', 'MENTON'
    ))
    RETURNING REF(EL) INTO REFBIBLIO8;

INSERT INTO BIBLIOTHEQUE_O EL VALUES (
            BIBLIOTHEQUE_T(
    9,'BIBLIOTHEQUE_9', 'Île-de-France', TAB_REF_EXEMPLAIRES_T(REFEXM7, REFEXM8), '63  Square de la Couronne', 'PARIS'
    ))
    RETURNING REF(EL) INTO REFBIBLIO9;

INSERT INTO BIBLIOTHEQUE_O EL VALUES (
            BIBLIOTHEQUE_T(
    10,'BIBLIOTHEQUE_10', 'Nord-Pas-de-Calais', TAB_REF_EXEMPLAIRES_T(REFEXM9), '32  Rue Hubert de Lisle', 'LOOS'
    ))
    RETURNING REF(EL) INTO REFBIBLIO10;

-------------------------------------------------------------------------ADHERENT----------------------------------------------------------------------------
INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    1, 'Martin', LIST_PRENOMS_T('Gabriel', 'A'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO1,REFBIBLIO2), '26 boulevard Renaud', '+33-655-537-820', 'punkis@icloud.fr', TO_DATE('11/02/1983', 'DD/MM/YYYY'), TO_DATE('08/11/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH1;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    2, 'Bernard', LIST_PRENOMS_T('Léo', 'B'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO2), '27 rue Barbe', '+33-735-554-648', 'skoch@yahoo.fr', TO_DATE('18/02/1973', 'DD/MM/YYYY'), TO_DATE('14/06/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH2;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    3, 'Thomas', LIST_PRENOMS_T('Raphaël', 'C'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO3), '28 avenue de Martins', '+33-655-544-986', 'mrobshaw@live.fr', TO_DATE('21/04/1988', 'DD/MM/YYYY'), TO_DATE('11/01/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH3;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    4, 'Petit', LIST_PRENOMS_T('Arthur', 'D'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO4), '29 place Charles', '+33-655-582-035', 'geekgrl@outlook.fr', TO_DATE('23/05/1967', 'DD/MM/YYYY'), TO_DATE('04/08/2020', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH4;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    5, 'Robert', LIST_PRENOMS_T('Louis', 'E'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO5), '30 impasse Muller', '+33-775-557-450', 'malin@msn.fr', TO_DATE('17/10/1984', 'DD/MM/YYYY'), TO_DATE('28/06/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH5;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    6, 'Richard', LIST_PRENOMS_T('Emma', 'F'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO6), '31 rue Lamy', '+33-785-550-994', 'hmbrand@sbcglobal.fr', TO_DATE('25/08/1967', 'DD/MM/YYYY'), TO_DATE('09/12/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH6;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    7, 'Durand', LIST_PRENOMS_T('Jade', 'E'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO7), '32 rue Roy', '+33-655-552-115', 'zeitlin@hotmail.fr', TO_DATE('26/01/1972', 'DD/MM/YYYY'), TO_DATE('21/10/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH7;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    8, 'Dubois', LIST_PRENOMS_T('Louise', 'R'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO8), '33 place Roger', '+33-655-584-492', 'lamky@gmail.fr', TO_DATE('02/06/2001', 'DD/MM/YYYY'), TO_DATE('01/04/2017', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH8;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    9, 'Moreau', LIST_PRENOMS_T('Lucas', 'R'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO9), '34 avenue Peron', '+33-700-555-126', 'bryanw@live.fr', TO_DATE('15/05/1994', 'DD/MM/YYYY'), TO_DATE('26/06/2017', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH9;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    10, 'Laurent', LIST_PRENOMS_T('Adam', 'R'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO10), '35 avenue Maurice', '+33-700-555-643', 'helger@att.fr', TO_DATE('07/03/1989', 'DD/MM/YYYY'), TO_DATE('15/04/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH10;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    11, 'Simon', LIST_PRENOMS_T('Maël', 'M'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO1), '36 impasse Blanc', '+33-700-555-172', 'gator@msn.fr', TO_DATE('27/02/1970', 'DD/MM/YYYY'), TO_DATE('20/07/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH11;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    12, 'Michel', LIST_PRENOMS_T('Jules', 'J'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO2), '37 place Lemaire', '+33-655-531-855', 'psharpe@verizon.fr', TO_DATE('05/04/1966', 'DD/MM/YYYY'), TO_DATE('23/12/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH12;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    13, 'Lefebvre', LIST_PRENOMS_T('Hugo', 'J'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO3), '38 rue Simon', '+33-700-555-300', 'fangorn@mac.fr', TO_DATE('10/04/1971', 'DD/MM/YYYY'), TO_DATE('03/09/2017', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH13;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    14, 'Leroy', LIST_PRENOMS_T('Alice', 'J'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO4), '39 rue de Blin', '+33-700-555-811', 'seano@verizon.fr', TO_DATE('01/02/1976', 'DD/MM/YYYY'), TO_DATE('07/11/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH14;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    15, 'Roux', LIST_PRENOMS_T('Liam', 'L'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO5), '40 place Breton', '+33-765-556-770', 'dexter@yahoo.fr', TO_DATE('08/01/1993', 'DD/MM/YYYY'), TO_DATE('18/11/2018', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH15;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    16, 'David', LIST_PRENOMS_T('Lina', 'L'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO6), '41 place Fernandez', '+33-655-529-040', 'fmerges@hotmail.fr', TO_DATE('14/02/1984', 'DD/MM/YYYY'), TO_DATE('06/05/2015', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH16;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    17, 'Bertrand', LIST_PRENOMS_T('Chloé', 'M'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO7), '42 chemin Perez', '+33-775-556-489', 'tedrlord@outlook.fr', TO_DATE('20/02/1989', 'DD/MM/YYYY'), TO_DATE('27/12/2016', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH17;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    18, 'Morel', LIST_PRENOMS_T('Noah', 'A'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO8), '43 chemin de Godard', '+33-700-555-252', 'gbacon@yahoo.fr', TO_DATE('19/08/1981', 'DD/MM/YYYY'), TO_DATE('10/08/2020', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH18;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    19, 'Fournier', LIST_PRENOMS_T('Ethan', 'P'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO9), '44 rue de Duval', '+33-700-555-964', 'seanq@yahoo.fr', TO_DATE('13/09/1992', 'DD/MM/YYYY'), TO_DATE('16/11/2018', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH19;
    

INSERT INTO ADHERENT_O AD VALUES (
            ADHERENT_T(
    20, 'Girard', LIST_PRENOMS_T('Paul', 'P'), TAB_REF_BIBLIOTHEQUES_T(REFBIBLIO10), '45 rue de Etienne', '+33-655-543-488', 'dkeeler@verizon.fr', TO_DATE('06/12/1990', 'DD/MM/YYYY'), TO_DATE('24/05/2019', 'DD-MM-YYYY'), 'Nice'
    ))
    RETURNING REF(AD) INTO REFADH20;
    
---------------------------------------------------------------------------------EMPRUNT----- ---------------------------------------------------------------------------  
INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    1, REFADH1, TO_DATE('21/01/2020', 'DD-MM-YYYY'), TO_DATE('21/02/2020', 'DD-MM-YYYY'), TO_DATE('15/02/2020', 'DD-MM-YYYY'), REFEXM1
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    2, REFADH2, TO_DATE('19/04/2020', 'DD-MM-YYYY'), TO_DATE('19/05/2020', 'DD-MM-YYYY'), TO_DATE('13/05/2020', 'DD-MM-YYYY'), REFEXM2
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    3, REFADH3, TO_DATE('05/02/2020', 'DD-MM-YYYY'), TO_DATE('05/03/2020', 'DD-MM-YYYY'), TO_DATE('01/03/2020', 'DD-MM-YYYY'), REFEXM3
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    4, REFADH4, TO_DATE('30/03/2020', 'DD-MM-YYYY'), TO_DATE('30/04/2020', 'DD-MM-YYYY'), TO_DATE('25/04/2020', 'DD-MM-YYYY'), REFEXM4
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    5, REFADH5, TO_DATE('06/08/2020', 'DD-MM-YYYY'), TO_DATE('06/09/2020', 'DD-MM-YYYY'), TO_DATE('01/09/2020', 'DD-MM-YYYY'), REFEXM5
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    6, REFADH6, TO_DATE('04/04/2020', 'DD-MM-YYYY'), TO_DATE('04/05/2020', 'DD-MM-YYYY'), TO_DATE('01/05/2020', 'DD-MM-YYYY'), REFEXM6
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    7, REFADH10, TO_DATE('06/08/2020', 'DD-MM-YYYY'), TO_DATE('06/09/2020', 'DD-MM-YYYY'), TO_DATE('01/09/2020', 'DD-MM-YYYY'), REFEXM7
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    8, REFADH8, TO_DATE('26/01/2020', 'DD-MM-YYYY'), TO_DATE('26/02/2020', 'DD-MM-YYYY'), TO_DATE('19/02/2020', 'DD-MM-YYYY'), REFEXM8
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    9, REFADH9, TO_DATE('26/08/2020', 'DD-MM-YYYY'), TO_DATE('26/09/2020', 'DD-MM-YYYY'), TO_DATE('23/09/2020', 'DD-MM-YYYY'), REFEXM9
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    10, REFADH10, TO_DATE('10/06/2020', 'DD-MM-YYYY'), TO_DATE('10/07/2020', 'DD-MM-YYYY'), TO_DATE('05/07/2020', 'DD-MM-YYYY'), REFEXM10
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    11, REFADH11, TO_DATE('14/05/2020', 'DD-MM-YYYY'), TO_DATE('14/06/2020', 'DD-MM-YYYY'), TO_DATE('10/06/2020', 'DD-MM-YYYY'), REFEXM1
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    12, REFADH12, TO_DATE('11/01/2020', 'DD-MM-YYYY'), TO_DATE('11/08/2020', 'DD-MM-YYYY'), TO_DATE('01/08/2020', 'DD-MM-YYYY'), REFEXM2
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    13, REFADH10, TO_DATE('23/04/2020', 'DD-MM-YYYY'), TO_DATE('23/05/2020', 'DD-MM-YYYY'), TO_DATE('01/05/2020', 'DD-MM-YYYY'), REFEXM1
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    14, REFADH8, TO_DATE('16/01/2020', 'DD-MM-YYYY'), TO_DATE('16/02/2020', 'DD-MM-YYYY'), TO_DATE('01/02/2020', 'DD-MM-YYYY'), REFEXM4
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    15, REFADH15, TO_DATE('07/06/2020', 'DD-MM-YYYY'), TO_DATE('07/07/2020', 'DD-MM-YYYY'), TO_DATE('01/07/2020', 'DD-MM-YYYY'), REFEXM5
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    16, REFADH16, TO_DATE('23/06/2020', 'DD-MM-YYYY'), TO_DATE('23/07/2020', 'DD-MM-YYYY'), NULL, REFEXM1
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    17, REFADH17, TO_DATE('20/08/2020', 'DD-MM-YYYY'), TO_DATE('20/09/2020', 'DD-MM-YYYY'), NULL, REFEXM9
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    18, REFADH18, TO_DATE('09/05/2020', 'DD-MM-YYYY'), TO_DATE('09/06/2020', 'DD-MM-YYYY'), NULL, REFEXM11
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    19, REFADH19, TO_DATE('23/04/2020', 'DD-MM-YYYY'), TO_DATE('23/07/2020', 'DD-MM-YYYY'), NULL, REFEXM8
    ));


INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    20, REFADH19, TO_DATE('05/05/2020', 'DD-MM-YYYY'), TO_DATE('05/06/2020', 'DD-MM-YYYY'), NULL, REFEXM9
    ));
    
INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    21, REFADH19, TO_DATE('05/05/2020', 'DD-MM-YYYY'), TO_DATE('01/06/2022', 'DD-MM-YYYY'), NULL, REFEXM9
    ));
    
INSERT INTO EMPRUNT_O VALUES (
            EMPRUNT_T(
    22, REFADH17, TO_DATE('07/07/2020', 'DD-MM-YYYY'), TO_DATE('01/06/2023', 'DD-MM-YYYY'), NULL, REFEXM1
    ));
    
    
END;
/
COMMIT;
------------------------------------------------TEST --------------------------------------------------------------------------------------
--- Test de la méthode getAuteur
SET SERVEROUTPUT ON
DECLARE
AUT1 AUTEUR_T;
AUT2 AUTEUR_T;
BEGIN
    SELECT VALUE(AUT) INTO AUT1 FROM AUTEUR_O AUT WHERE ID=1;
    AUT2 := AUT1.GETAUTEUR;
    DBMS_OUTPUT.PUT_LINE('aut1.NOM='||AUT1.NOM);
	DBMS_OUTPUT.PUT_LINE('aut2.NOM='||AUT2.NOM);
	EXCEPTION
		WHEN OTHERS THEN
				DBMS_OUTPUT.PUT_LINE('sqlcode='||SQLCODE);
				DBMS_OUTPUT.PUT_LINE('sqlerrm='||SQLERRM);
END;
/
COMMIT;

------------------------------------------------Requêtes de consultation --------------------------------------------------------------------------------------
--Rechercher tous les catalogues par titre
SELECT C.TITRE 
FROM CATALOGUE_O C;

--Rechercher tous les REF_EXEMPLAIRES par le titre de catalogue
SELECT *
FROM EXEMPLAIRE_O EX
WHERE EX.REF_CATALOGUE.TITRE = 'LIVRE5';

--Rechercher tous les REF_EXEMPLAIRES dans certaine bibliothèque par le titre de catalogue et l’id de bibliothèque
SELECT EXS.COLUMN_VALUE.EXNO
FROM BIBLIOTHEQUE_O B, TABLE(B.REF_EXEMPLAIRES) EXS 
WHERE B.ID = 1 AND EXS.COLUMN_VALUE.REF_CATALOGUE.TITRE = 'LIVRE6';


--Rechercher tous les catalogues par le nom d’auteur
SELECT C.TITRE 
FROM CATALOGUE_O C, TABLE(C.REF_AUTEURS) A 
WHERE A.COLUMN_VALUE.NOM = 'GIRARD';

--Rechercher tous les REF_EXEMPLAIRES dans certaine bibliothèque par le nom d’auteur
SELECT EXS.COLUMN_VALUE.EXNO, EXS.COLUMN_VALUE.REF_CATALOGUE.TITRE 
FROM BIBLIOTHEQUE_O B, TABLE(B.REF_EXEMPLAIRES) EXS, TABLE(EXS.COLUMN_VALUE.REF_CATALOGUE.REF_AUTEURS) A
WHERE B.ID = 1 AND A.COLUMN_VALUE.NOM = 'GIRARD';

--Rechercher tous les emprunts qui sont en retard
SELECT E.ID FROM EMPRUNT_O E WHERE E.TESTRETARD() = 1;

--Rechercher tous les adhérents qui ont pas retourné les livres empruntés
SELECT EMP.REF_ADHERENT.NOM ,EMP.REF_ADHERENT.PHONE , EMP.ID
FROM EMPRUNT_O EMP
WHERE EMP.TESTRETARD() = 1;

--Rechercher les adhérents de la bibliothèque 1 par le nom de la bibliothèque(&nom)
SELECT AD.NOM,AD.PHONE,AD.NUMERO_ADHERENT
FROM ADHERENT_O AD , TABLE(AD.REF_BIBLIOTHEQUES) ADREF 
WHERE ADREF.COLUMN_VALUE.NOM =  'BIBLIOTHEQUE_1' ;

--Rechercher tous les exemplaires qui ne sont pas encore retournés et sont donc en retard(date de fin de l'emprunt du livre dépassé sans que l'adhérent retourne le livre)
SELECT  EMP.REF_EXEMPLAIRE.EXNO AS ID_EXEMPLAIRE, EMP.REF_EXEMPLAIRE.REF_CATALOGUE.TITRE AS TITRE , COUNT(EMP.REF_EXEMPLAIRE) AS EXEMPLAIRE_EN_RETARD
FROM EMPRUNT_O EMP
WHERE EMP.TESTRETARD()=1
GROUP BY EMP.REF_EXEMPLAIRE;

--Rechercher tous les exemplaires avec un emprunt valide(les exemplaires qui ne sont pas encore retournés mais qui ne sont pas en retard(date de fin de l'emprunt du livre pas encore dépassé))
SELECT EMP.REF_EXEMPLAIRE.EXNO AS ID_EXEMPLAIRE, EMP.REF_EXEMPLAIRE.REF_CATALOGUE.TITRE AS TITRE ,COUNT(EMP.REF_EXEMPLAIRE) AS EMPRUNT_VALIDE
FROM EMPRUNT_O EMP
WHERE EMP.DATE_END > CURRENT_DATE AND DATE_RETOUR IS NULL
GROUP BY EMP.REF_EXEMPLAIRE;

--Pour chaque adhérent donner le nombre de livre qu'il a empruntée
SELECT EMP.REF_ADHERENT.NOM AS NOM, COUNT(EMP.REF_ADHERENT) AS NB_LIVRE_EMPRUNTÉ
FROM EMPRUNT_O EMP
GROUP BY EMP.REF_ADHERENT;

------------------------------------------------Requêtes de mises à jour et suppression --------------------------------------------------------------------------------------
--Mettre à jour le numéro de téléphone de l'adhérent numéro 2
UPDATE ADHERENT_O
SET PHONE = '+33-675-437-880'
WHERE NUMERO_ADHERENT = 2;

--Mise à jour d'un champ VARRAY
UPDATE AUTEUR_O
SET PRENOMS = LIST_PRENOMS_T('Grizou','Pogba')
WHERE ID = 1;

--Update la date_end  de l'emprunt numéro 5
UPDATE EMPRUNT_O
SET DATE_END = DATE_END + 2
WHERE ID = 5;


--Suppression de l'adhérent numéro 3
DECLARE
ADH1    REF ADHERENT_T;
BEGIN
    DELETE FROM ADHERENT_O AD WHERE NUMERO_ADHERENT= 3 
    RETURNING REF(AD) INTO ADH1;
    
    DELETE FROM EMPRUNT_O EMP WHERE EMP.REF_ADHERENT=ADH1;
END;
/
