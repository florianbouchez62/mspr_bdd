-- ==============
-- Suppression de l'utilisateur & tablespace (SYSDBA only, attention les données sont supprimées)
-- ==============

drop tablespace rparis_tablespace including contents;
drop tablespace rparis_tablespace_temp including contents;
drop user rparis;


-- ==============
-- Suppression des tables et séquences
-- ==============

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
DROP TABLE TYPEDECHET;
DROP TABLE EMPLOYE;
DROP TABLE CENTRETRAITEMENT;
DROP TABLE ENTREPRISE;