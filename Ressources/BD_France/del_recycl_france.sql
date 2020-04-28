-- ==============
-- Suppression de l'utilisateur & tablespace (SYSDBA only, attention les données sont supprimées)
-- ==============

drop tablespace rfrance_tablespace including contents;
drop tablespace rfrance_tablespace_temp including contents;
drop user rfrance;


-- ==============
-- Suppression des tables et séquences
-- ==============

DROP SEQUENCE SEQ_SITE;
DROP SEQUENCE SEQ_CENTRE;
DROP SEQUENCE SEQ_DEMANDE;
DROP SEQUENCE SEQ_EMPLOYE;
DROP SEQUENCE SEQ_TOURNEE;
DROP SEQUENCE SEQ_TYPEDECHET;

DROP TABLE DETAILDEPOT;
DROP TABLE DETAILDEMANDE;
DROP TABLE DEMANDE;
DROP TABLE TOURNEE;
DROP TABLE CAMION;
DROP TABLE EMPLOYE;
DROP TABLE SITE;
DROP TABLE TYPEDECHET;
DROP TABLE FONCTION;
DROP TABLE CENTRETRAITEMENT;
DROP TABLE ENTREPRISE;