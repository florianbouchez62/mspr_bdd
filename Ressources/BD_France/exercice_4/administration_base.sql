-- =====================================
-- FICHIER A EXECUTER EN TANT QUE SYSDBA
-- =====================================
-- Création des vues
-- =====================================

-- Vue affichant l'ensemble des employés en fonction du site de l'utilisateur connecté, sans les informations "sensibles"
CREATE OR REPLACE VIEW RFRANCE.EMPLOYES_SITE AS
    SELECT EMPLOYE.NOEMPLOYE, EMPLOYE.NOM, EMPLOYE.PRENOM, EMPLOYE.DATENAISS, FONCTION.NOMFONCTION
    FROM RFRANCE.EMPLOYE
            JOIN RFRANCE.FONCTION ON EMPLOYE.NOFONCTION = FONCTION.NOFONCTION
    WHERE EMPLOYE.NOSITE = (SELECT NOSITE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER);

-- Vue affichant l'ensemble des camions en fonction du site de l'utilisateur connecté
CREATE OR REPLACE VIEW RFRANCE.CAMIONS_SITE AS
    SELECT CAMION.NOIMMATRIC, CAMION.MODELE, CAMION.MARQUE, CAMION.MAXENLEVEMENTS
    FROM RFRANCE.CAMION
    WHERE CAMION.NOSITE = (SELECT NOSITE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER);

-- Vue affichant l'ensemble des demandes en fonction du site de l'utilisateur connecté
CREATE OR REPLACE VIEW RFRANCE.DEMANDES_SITE AS
    SELECT *
    FROM RFRANCE.DEMANDE
    WHERE DEMANDE.NOSITE = (SELECT NOSITE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER);

-- Vue affichant l'ensemble des demandes non traitées en fonction du site de l'utilisateur connecté
CREATE OR REPLACE VIEW RFRANCE.DEMANDES_NON_TRAITEES_SITE AS
    SELECT *
    FROM RFRANCE.DEMANDENONTRAITEE
    WHERE DEMANDENONTRAITEE.NOSITE = (SELECT NOSITE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER);

-- Vue affichant l'ensemvle des détails des demandes en fonction du site de l'utilisateur connecté
CREATE OR REPLACE VIEW RFRANCE.DETAIL_DEMANDES_SITE AS
    SELECT DETAILDEMANDE.*
    FROM RFRANCE.DETAILDEMANDE
        JOIN RFRANCE.DEMANDE ON DETAILDEMANDE.NODEMANDE = DEMANDE.NODEMANDE
    WHERE DEMANDE.NOSITE = (SELECT NOSITE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER);

-- Vue affichant l'ensemble des tournées en fonction du site de l'utilisateur connecté
CREATE OR REPLACE VIEW RFRANCE.TOURNEES_SITE AS
    SELECT TOURNEE.*
    FROM RFRANCE.TOURNEE
        JOIN RFRANCE.CAMION ON TOURNEE.NOIMMATRIC = CAMION.NOIMMATRIC
        JOIN RFRANCE.EMPLOYE ON TOURNEE.NOEMPLOYE = EMPLOYE.NOEMPLOYE
    WHERE CAMION.NOSITE = (SELECT NOSITE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER)
        AND EMPLOYE.NOSITE = (SELECT NOSITE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER);

-- Vue affichant l'ensemble des dépots pour les tournées d'un site
CREATE OR REPLACE VIEW RFRANCE.DETAIL_DEPOTS_SITE AS
    SELECT DETAILDEPOT.*
    FROM RFRANCE.DETAILDEPOT
        JOIN RFRANCE.TOURNEE ON DETAILDEPOT.NOTOURNEE = TOURNEE.NOTOURNEE
        JOIN RFRANCE.EMPLOYE ON EMPLOYE.NOEMPLOYE = TOURNEE.NOEMPLOYE
    WHERE EMPLOYE.NOSITE = (SELECT NOSITE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER);

-- Vue affichant l'ensemble des tournées d'un employé
CREATE OR REPLACE VIEW RFRANCE.TOURNEES_EMPLOYE AS
    SELECT *
    FROM RFRANCE.TOURNEE
    WHERE NOEMPLOYE = (SELECT NOEMPLOYE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER);

-- Vue affichant l'ensemble des demandes associées aux tournées d'un employé
CREATE OR REPLACE VIEW RFRANCE.DEMANDES_EMPLOYE AS
    SELECT DEMANDE.*
    FROM RFRANCE.DEMANDE
        JOIN RFRANCE.TOURNEE ON DEMANDE.NOTOURNEE = TOURNEE.NOTOURNEE
    WHERE TOURNEE.NOEMPLOYE = (SELECT NOEMPLOYE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER);

-- Vue affichant l'ensemble des enlèvements des demandes associées aux tournées d'un employé
CREATE OR REPLACE VIEW RFRANCE.DETAIL_DEMANDES_EMPLOYE AS
    SELECT DETAILDEMANDE.*
    FROM RFRANCE.DETAILDEMANDE
        JOIN RFRANCE.DEMANDE ON DETAILDEMANDE.NODEMANDE = DEMANDE.NODEMANDE
        JOIN RFRANCE.TOURNEE ON DEMANDE.NOTOURNEE = TOURNEE.NOTOURNEE
    WHERE TOURNEE.NOEMPLOYE = (SELECT NOEMPLOYE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER);

-- Vue affichant l'ensemble des dépôts associés aux tournées d'un employé
CREATE OR REPLACE VIEW RFRANCE.DETAIL_DEPOTS_EMPLOYE AS
    SELECT DETAILDEPOT.*
    FROM RFRANCE.DETAILDEPOT
        JOIN RFRANCE.TOURNEE ON DETAILDEPOT.NOTOURNEE = TOURNEE.NOTOURNEE
    WHERE TOURNEE.NOEMPLOYE = (SELECT NOEMPLOYE FROM RFRANCE.EMPLOYE WHERE USERNAME = USER);

-- =====================================
-- Création des triggers
-- =====================================

-- Trigger vérifiant que le camion et l'employé d'une tournée sont du même site que l'utilisateur créeant ou modifiant
-- la tournée
CREATE OR REPLACE TRIGGER RFRANCE.VERIF_CAMION_EMPLOYEE_SITE BEFORE INSERT OR UPDATE ON RFRANCE.TOURNEE FOR EACH ROW
    DECLARE
        v_numsite INTEGER;
        v_camion RFRANCE.CAMION%ROWTYPE;
        v_employe RFRANCE.EMPLOYE%ROWTYPE;
    BEGIN
        SELECT NOSITE INTO v_numsite FROM RFRANCE.EMPLOYE WHERE USERNAME = USER;
        SELECT CAMION.* INTO v_camion FROM RFRANCE.CAMION WHERE NOIMMATRIC = :new.NOIMMATRIC;
        SELECT EMPLOYE.* INTO v_employe FROM RFRANCE.EMPLOYE WHERE NOEMPLOYE = :new.NOEMPLOYE;
        IF v_camion.NOSITE != v_numsite OR v_employe.NOSITE != v_numsite THEN
            RAISE_APPLICATION_ERROR(-20001, 'Affectation impossible du camion/employé car son site est différent du vôtre.');
        END IF;
    END;

-- Trigger vérifiant, lors de l'affectation d'une demande à une tournée, que le camion et l'employé associé à la tournée
-- est du même site que le site de la demande. La demande devant être du même site que l'utilisateur connecté.
CREATE OR REPLACE TRIGGER RFRANCE.VERIF_AFFECTATION_TOURNEE_SITE BEFORE INSERT OR UPDATE ON RFRANCE.DEMANDE FOR EACH ROW
    DECLARE
        v_numsite INTEGER;
        v_camion RFRANCE.CAMION%ROWTYPE;
        v_employe RFRANCE.EMPLOYE%ROWTYPE;
    BEGIN
        IF :new.NOTOURNEE IS NOT NULL THEN
            SELECT NOSITE INTO v_numsite FROM RFRANCE.EMPLOYE WHERE USERNAME = USER;
            SELECT CAMION.* INTO v_camion FROM RFRANCE.CAMION JOIN RFRANCE.TOURNEE ON CAMION.NOIMMATRIC = TOURNEE.NOIMMATRIC WHERE NOTOURNEE = :new.NOTOURNEE;
            SELECT EMPLOYE.* INTO v_employe FROM RFRANCE.EMPLOYE JOIN RFRANCE.TOURNEE ON EMPLOYE.NOEMPLOYE = TOURNEE.NOEMPLOYE WHERE NOTOURNEE = :new.NOTOURNEE;
            IF :new.NOSITE != v_numsite THEN
                RAISE_APPLICATION_ERROR(-20001, 'Création/modification impossible de la demande car son site est différent du vôtre.');
            END IF;
            IF v_camion.NOSITE != v_numsite OR v_employe.NOSITE != v_numsite THEN
                RAISE_APPLICATION_ERROR(-20001, 'Création/modification impossible de la demande car le site associé au camion ou à employé de la tournée est différent du vôtre.');
            END IF;
        END IF;
    END;

-- Trigger vérifiant, pour un enlèvement, que la demande associée est bien associée à une tournée de l'employé
CREATE OR REPLACE TRIGGER RFRANCE.VERIF_DEMANDE_TOURNEE_EMPLOYE BEFORE INSERT OR UPDATE ON RFRANCE.DETAILDEMANDE FOR EACH ROW
    DECLARE
        v_numemploye INTEGER;
        v_demande RFRANCE.DEMANDE%ROWTYPE;
        v_numemploye_demande INTEGER;
    BEGIN
        SELECT NOEMPLOYE INTO v_numemploye FROM RFRANCE.EMPLOYE WHERE USERNAME = USER;
        SELECT * INTO v_demande FROM RFRANCE.DEMANDE WHERE NODEMANDE = :new.NODEMANDE;
        SELECT NOEMPLOYE INTO v_numemploye_demande FROM RFRANCE.TOURNEE WHERE NOTOURNEE = v_demande.NOTOURNEE;
        IF v_numemploye_demande != v_numemploye THEN
            RAISE_APPLICATION_ERROR(-20001, 'Vous ne pouvez pas effectuer un enlèvement sur cette demande, la tournée associée ne vous est pas attribuée');
        END IF;
    END;

-- Trigger vérifiant, pour un dépôt, que la tournée associée est bien associée à un employé
CREATE OR REPLACE TRIGGER RFRANCE.VERIF_DEPOT_TOURNEE_EMPLOYE BEFORE INSERT OR UPDATE ON RFRANCE.DETAILDEPOT FOR EACH ROW
    DECLARE
        v_numemploye INTEGER;
        v_tournee RFRANCE.TOURNEE%ROWTYPE;
    BEGIN
        SELECT NOEMPLOYE INTO v_numemploye FROM RFRANCE.EMPLOYE WHERE USERNAME = USER;
        SELECT * INTO v_tournee FROM RFRANCE.TOURNEE WHERE NOTOURNEE = :new.NOTOURNEE;
        IF v_numemploye != v_tournee.NOEMPLOYE THEN
            RAISE_APPLICATION_ERROR(-20001, 'Vous ne pouvez pas effectuer un dépot pour cette tournée car elle ne vous y est pas associée.');
        END IF;
    END;

-- =====================================
-- Création des rôles
-- =====================================

-- Direction générale (accès à toutes les informations de la BD en lecture)
CREATE ROLE direction_generale;
GRANT SELECT ON RFRANCE.CAMION TO direction_generale;
GRANT SELECT ON RFRANCE.CENTRETRAITEMENT TO direction_generale;
GRANT SELECT ON RFRANCE.DEMANDE TO direction_generale;
GRANT SELECT ON RFRANCE.DEMANDENONTRAITEE TO direction_generale;
GRANT SELECT ON RFRANCE.DETAILDEMANDE TO direction_generale;
GRANT SELECT ON RFRANCE.DETAILDEPOT TO direction_generale;
GRANT SELECT ON RFRANCE.EMPLOYE TO direction_generale;
GRANT SELECT ON RFRANCE.ENTREPRISE TO direction_generale;
GRANT SELECT ON RFRANCE.FONCTION TO direction_generale;
GRANT SELECT ON RFRANCE.SITE TO direction_generale;
GRANT SELECT ON RFRANCE.TOURNEE TO direction_generale;
GRANT SELECT ON RFRANCE.TYPEDECHET TO direction_generale;

-- Direction RH (ajout, modification, suppression d'employés)
CREATE ROLE direction_rh;
GRANT SELECT, INSERT, UPDATE, DELETE ON RFRANCE.EMPLOYE TO direction_rh;
GRANT SELECT ON RFRANCE.FONCTION TO direction_rh;
GRANT SELECT ON RFRANCE.SITE TO direction_rh;

-- Direction commerciale (ajout, modification, suppression de centres de traitement)
CREATE ROLE direction_commerciale;
GRANT SELECT, INSERT, UPDATE, DELETE ON RFRANCE.CENTRETRAITEMENT TO direction_commerciale;

-- Agents organisant les tournées
CREATE ROLE agent_organisation_tournee;
GRANT SELECT, INSERT, UPDATE ON RFRANCE.ENTREPRISE TO agent_organisation_tournee;
GRANT SELECT, INSERT, UPDATE ON RFRANCE.TOURNEES_SITE TO agent_organisation_tournee;
GRANT SELECT, UPDATE ON RFRANCE.DEMANDES_SITE TO agent_organisation_tournee;
GRANT SELECT ON RFRANCE.DEMANDES_NON_TRAITEES_SITE TO agent_organisation_tournee;
GRANT SELECT ON RFRANCE.CAMIONS_SITE TO agent_organisation_tournee;
GRANT SELECT ON RFRANCE.EMPLOYES_SITE TO agent_organisation_tournee;

-- Responsable de site (observer l'activité de son site)
CREATE ROLE responsable_site;
GRANT SELECT ON RFRANCE.ENTREPRISE TO responsable_site;
GRANT SELECT ON RFRANCE.CENTRETRAITEMENT TO responsable_site;
GRANT SELECT ON RFRANCE.TOURNEES_SITE TO responsable_site;
GRANT SELECT ON RFRANCE.DEMANDES_SITE TO responsable_site;
GRANT SELECT ON RFRANCE.DEMANDES_NON_TRAITEES_SITE TO responsable_site;
GRANT SELECT ON RFRANCE.DETAIL_DEMANDES_SITE TO responsable_site;
GRANT SELECT ON RFRANCE.DETAIL_DEPOTS_SITE TO responsable_site;
GRANT SELECT ON RFRANCE.TYPEDECHET TO responsable_site;
GRANT SELECT ON RFRANCE.EMPLOYES_SITE TO responsable_site;
GRANT SELECT ON RFRANCE.CAMIONS_SITE TO responsable_site;

-- Employé (visualisation des données de ses tournées, et possibilité d'ajout detaildemande & détaildépot)
CREATE ROLE employe;
GRANT SELECT ON RFRANCE.TYPEDECHET TO employe;
GRANT SELECT ON RFRANCE.CENTRETRAITEMENT TO employe;
GRANT SELECT ON RFRANCE.ENTREPRISE TO employe;
GRANT SELECT ON RFRANCE.TOURNEES_EMPLOYE TO employe;
GRANT SELECT ON RFRANCE.DEMANDES_EMPLOYE TO employe;
GRANT SELECT, INSERT, UPDATE, DELETE ON RFRANCE.DETAIL_DEMANDES_EMPLOYE TO employe;
GRANT SELECT, INSERT, UPDATE, DELETE ON RFRANCE.DETAIL_DEPOTS_EMPLOYE TO employe;

-- =====================================
-- Création des profils
-- =====================================

-- Profil employé standard
CREATE PROFILE rfrance_employe
LIMIT
    PASSWORD_LIFE_TIME 60 -- Durée de validité du mot de passe (60 jours)
    SESSIONS_PER_USER 1 -- Nombre de sessions simultanées (1)
    FAILED_LOGIN_ATTEMPTS 3; -- Nombre de tentatives de connexions erronnées (3)

-- Profil direction & responsables
CREATE PROFILE rfrance_responsable
LIMIT
    PASSWORD_LIFE_TIME 60
    SESSIONS_PER_USER 2
    FAILED_LOGIN_ATTEMPTS 3;

-- =====================================
-- Exemple de script création des comptes utilisateurs
-- =====================================

DECLARE
    CURSOR c_employes IS
        SELECT EMPL.NOM, EMPL.PRENOM, EMPL.USERNAME
        FROM RFRANCE.EMPLOYE EMPL;
    v_prefix VARCHAR(2);
    v_profile VARCHAR(255);
    v_role VARCHAR(255);
BEGIN
    FOR emp IN c_employes
        LOOP
            DBMS_OUTPUT.PUT_LINE('Création de compte pour ' || emp.PRENOM || ' ' || emp.NOM || ' (username/password) : ' || emp.USERNAME || '/' || emp.USERNAME);
            v_prefix := SUBSTR(emp.USERNAME, 1, 2);
            IF v_prefix = 'D_' OR v_prefix = 'R_' THEN
                v_profile := 'rfrance_responsable';
            ELSE
                v_profile := 'rfrance_employe';
            END IF;
            EXECUTE IMMEDIATE 'CREATE USER '||emp.USERNAME||' IDENTIFIED BY '||emp.USERNAME|| ' DEFAULT TABLESPACE ' ||
                              'RFRANCE_TABLESPACE TEMPORARY TABLESPACE RFRANCE_TABLESPACE_TEMP PROFILE ' || v_profile ||
                              ' PASSWORD EXPIRE';
            EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO '|| emp.USERNAME;
            -- Par défaut, pas d'attribution des roles direction et responsables, à effectuer manuellement
            IF v_prefix = 'A_' THEN
                v_role := 'agent_organisation_tournee';
                EXECUTE IMMEDIATE 'GRANT ' || v_role || ' TO ' || emp.USERNAME;
            ELSIF v_prefix = 'E_' THEN
                v_role := 'employe';
                EXECUTE IMMEDIATE 'GRANT ' || v_role || ' TO ' || emp.USERNAME;
            END IF;
        END LOOP;
END;
