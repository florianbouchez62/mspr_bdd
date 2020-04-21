-- ==============
-- Suppression de l'utilisateur & tablespace (SYSDBA only, attention les données sont supprimées)
-- ==============

drop tablespace rlille_tablespace including contents;
drop tablespace rlille_tablespace_temp including contents;
drop user rlille;


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
DROP TABLE EMPLOYE;
DROP TABLE CAMION;
DROP TABLE TYPEDECHET;
DROP TABLE FONCTION;
DROP TABLE CENTRETRAITEMENT;
DROP TABLE ENTREPRISE;



