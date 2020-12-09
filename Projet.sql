
drop type   AUTEUR_T force;
drop type   TAB_REF_AUTEURS force ;
drop type   CATALOGUE_T force;
drop type   EXEMPLAIRE_T force;
drop type   TABEXEMPLAIRES_T force;
drop type   BIBLIOTHEQUE_T force;
drop type   ADHERENT_T force;
drop type   TABPRENOMS_T force;
drop type   TAB_REF_BIBLIOTHEQUE force;
drop type   EMPRUNT_T force;
drop type   RESEAU_T force;



CREATE OR REPLACE TYPE AUTEUR_T
/

CREATE OR REPLACE TYPE TAB_REF_AUTEURS AS TABLE OF REF AUTEUR_T
/

CREATE OR REPLACE TYPE CATALOGUE_T
/

CREATE OR REPLACE TYPE CATALOGUE_T AS OBJECT(
ID                  NUMBER(4),
TITRE               VARCHAR2(20),
ANNEE_EDITION       DATE,
MAISON_EDITION      VARCHAR2(20),
REF_AUTEURS         TAB_REF_AUTEURS,
DESCRIPTION         CLOB,
MAP MEMBER FUNCTION compAnneeEDITION return DATE  -- comparer avec ANNEE_EDITION décroissant
);
/

CREATE OR REPLACE TYPE EXEMPLAIRE_T AS OBJECT(
ID                  NUMBER(4),
REF_CATALOGUE       REF CATALOGUE_T,
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

CREATE OR REPLACE TYPE TAB_REF_BIBLIOTHEQUE AS TABLE OF REF BIBLIOTHEQUE_T
/

CREATE OR REPLACE TYPE ADHERENT_T AS OBJECT(
NUMERO_ADHERENT            NUMBER(4),
NOM                        VARCHAR2(20),
PRENOMS                    TABPRENOMS_T,
REF_BIBLIOTHEQUE           TAB_REF_BIBLIOTHEQUE,
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


CREATE OR REPLACE TYPE TAB_REF_BIBLIOTHEQUE_T AS TABLE OF REF BIBLIOTHEQUE_T
/

CREATE OR REPLACE TYPE RESEAU_T AS OBJECT(
ID                          NUMBER(4),
NOM                         VARCHAR(20),
BIBLIOTHEQUES               TAB_REF_BIBLIOTHEQUE_T,
MAP MEMBER FUNCTION compNom return VARCHAR2 -- comparer avec NOM croissant
);
/



