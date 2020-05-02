----------------------------------------------------------------------------------------------
-- Quantité totale collectée pour un type de déchet sur une période donnée au niveau d'un site
----------------------------------------------------------------------------------------------

-- Fonction

CREATE OR REPLACE FUNCTION QUANTITE_TYPEDECHET_SITE_PERIODE (NUMEROSITE IN INTEGER, LIBELLETYPEDECHET IN VARCHAR,
DEBUTPERIODE IN VARCHAR, FINPERIODE IN VARCHAR) RETURN INTEGER AS
    CURSOR enlevements IS
        SELECT DD.QUANTITEENLEVEE
        FROM DETAILDEMANDE DD
            JOIN TYPEDECHET T on DD.NOTYPEDECHET = T.NOTYPEDECHET
            JOIN DEMANDE D on DD.NODEMANDE = D.NODEMANDE
        WHERE D.NOSITE = NUMEROSITE
          AND T.NOMTYPEDECHET = LIBELLETYPEDECHET
          AND D.DATEENLEVEMENT BETWEEN TO_DATE(DEBUTPERIODE, 'yyyy/mm/dd') AND TO_DATE(FINPERIODE, 'yyyy/mm/dd');
    quantite INTEGER := 0;
BEGIN
    FOR enlevement IN enlevements
        LOOP
            quantite := quantite + enlevement.QUANTITEENLEVEE;
        END LOOP;
    RETURN quantite;
END;

-- Utilisation

BEGIN
    DBMS_OUTPUT.PUT_LINE(QUANTITE_TYPEDECHET_SITE_PERIODE(1,'Papier','2018-09-01', '2018-10-30'));
END;

----------------------------------------------------------------------------------------------
-- Quantité totale collectée pour un type de déchet sur une période donnée au niveau national
----------------------------------------------------------------------------------------------

-- Fonction

CREATE OR REPLACE FUNCTION QUANTITE_TYPEDECHET_NATIONAL_PERIODE (LIBELLETYPEDECHET IN VARCHAR, DEBUTPERIODE IN VARCHAR,
FINPERIODE IN VARCHAR) RETURN INTEGER AS
    CURSOR sites IS
        SELECT NOSITE FROM SITE;
    quantite_nationale INTEGER := 0;
BEGIN
    FOR site IN sites
        LOOP
            quantite_nationale :=
                quantite_nationale + QUANTITE_TYPEDECHET_SITE_PERIODE(site.NOSITE, LIBELLETYPEDECHET, DEBUTPERIODE, FINPERIODE);
        END LOOP;
    RETURN quantite_nationale;
END;

-- Utilisation

BEGIN
    DBMS_OUTPUT.PUT_LINE(QUANTITE_TYPEDECHET_NATIONAL_PERIODE('Papier','2018-09-01', '2018-10-30'));
END;

----------------------------------------------------------------------------------------------
-- Parcours des demandes non inscrites et affectation dans une tournée
----------------------------------------------------------------------------------------------

-- Procédure
CREATE OR REPLACE PROCEDURE INSCRIPTION_DEMANDES_TOURNEES AS
    CURSOR sites IS
        SELECT NOSITE as NUM, NOMSITE as NOM
        FROM SITE;
    v_tourneesDispos INTEGER := 0;
    v_dateAttribution DATE;
    v_tournee TOURNEES_DISPONIBLES%ROWTYPE;
BEGIN
    FOR site IN sites
        LOOP
            DBMS_OUTPUT.PUT_LINE('Parcours des demandes non inscrites de ' || site.NOM);
            FOR demande IN (SELECT * FROM DEMANDE WHERE NOSITE = site.NUM AND NOTOURNEE IS NULL)
                LOOP
                    v_dateAttribution := DEMANDE.DATEENLEVEMENT;
                    v_tourneesDispos := NOMBRE_TOURNEES_DISPONIBLES(site.NUM, v_dateAttribution);
                    IF v_tourneesDispos > 0 THEN
                        SELECT * INTO v_tournee FROM TOURNEES_DISPONIBLES WHERE DATETOURNEE = v_dateAttribution AND NOSITE = site.NUM FETCH FIRST ROW ONLY;
                        AFFICHE_AFFECTATION(demande.NODEMANDE, v_tournee.NOTOURNEE, v_dateAttribution);
                        AFFECTATION_DEMANDE_TOURNEE(demande.NODEMANDE, v_tournee.NOTOURNEE);
                    ELSE
                        v_dateAttribution := v_dateAttribution + INTERVAL '1' DAY;
                        AFFICHE_ECHEC_AFFECTATION(demande.NODEMANDE, v_dateAttribution);
                        v_tourneesDispos := NOMBRE_TOURNEES_DISPONIBLES(site.NUM, v_dateAttribution);
                        IF v_tourneesDispos > 0 THEN
                            SELECT * INTO v_tournee FROM TOURNEES_DISPONIBLES WHERE DATETOURNEE = v_dateAttribution AND NOSITE = site.NUM FETCH FIRST ROW ONLY;
                            AFFICHE_AFFECTATION(demande.NODEMANDE, v_tournee.NOTOURNEE, v_dateAttribution);
                            AFFECTATION_DEMANDE_TOURNEE(demande.NODEMANDE, v_tournee.NOTOURNEE);
                        ELSE
                            v_dateAttribution := v_dateAttribution + INTERVAL '1' DAY;
                            AFFICHE_ECHEC_AFFECTATION(demande.NODEMANDE, v_dateAttribution);
                            v_tourneesDispos := NOMBRE_TOURNEES_DISPONIBLES(site.NUM, v_dateAttribution);
                            IF v_tourneesDispos > 0 THEN
                                SELECT * INTO v_tournee FROM TOURNEES_DISPONIBLES WHERE DATETOURNEE = v_dateAttribution AND NOSITE = site.NUM FETCH FIRST ROW ONLY;
                                AFFICHE_AFFECTATION(demande.NODEMANDE, v_tournee.NOTOURNEE, v_dateAttribution);
                                AFFECTATION_DEMANDE_TOURNEE(demande.NODEMANDE, v_tournee.NOTOURNEE);
                            ELSE
                                AFFICHE_ECHEC_AFFECTATION(demande.NODEMANDE);
                                DEPLACEMENT_DEMANDE_VERS_DEMANDE_NON_TRAITEE(demande.NODEMANDE);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
        END LOOP;
END;

-- Dépendances de procédure

---- Nombre de demandes affectées sur chaque tournée, avec le nombre max d'enlèvements sur la tournée
CREATE OR REPLACE VIEW NB_DEMANDES_AFFECTEES_TOURNEE AS
    SELECT TOURNEE.NOTOURNEE, TOURNEE.DATETOURNEE, TOURNEE.NOIMMATRIC, SITE.NOSITE, CAMION.MAXENLEVEMENTS, COUNT(DEMANDE.NODEMANDE) AS NBDEMANDES
    FROM TOURNEE
        LEFT JOIN DEMANDE ON TOURNEE.NOTOURNEE = DEMANDE.NOTOURNEE
        LEFT JOIN CAMION ON CAMION.NOIMMATRIC = TOURNEE.NOIMMATRIC
        LEFT JOIN SITE ON SITE.NOSITE = CAMION.NOSITE
    GROUP BY TOURNEE.NOTOURNEE, TOURNEE.DATETOURNEE, TOURNEE.NOIMMATRIC, SITE.NOSITE, CAMION.MAXENLEVEMENTS
    ORDER BY SITE.NOSITE;

---- Liste des tournées pouvant accueillir des nouvelles demandes (nbre demandes sur la tournée inférieure à la capacité
---- maximale d'enlèvements du camion associé)
CREATE OR REPLACE VIEW TOURNEES_DISPONIBLES AS
    SELECT *
    FROM NB_DEMANDES_AFFECTEES_TOURNEE
    WHERE NBDEMANDES < MAXENLEVEMENTS;

---- Procédure shortcut pour afficher un message d'affectation d'une demande à une tournée
CREATE OR REPLACE PROCEDURE AFFICHE_AFFECTATION (NODEMANDE INTEGER, NOTOURNEE INTEGER, DATEAFFECTATION DATE) AS
    BEGIN
       DBMS_OUTPUT.PUT_LINE('Affectation de la demande n°' || NODEMANDE || ' à la tournée n°' || NOTOURNEE || ' le ' || DATEAFFECTATION);
    END;

---- Procédure shortcut pour afficher un message d'affectation échouée d'une demande à une tournée
CREATE OR REPLACE PROCEDURE AFFICHE_ECHEC_AFFECTATION(NODEMANDE INTEGER, NEXTDATE DATE := NULL) AS
    BEGIN
        IF NEXTDATE IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('Affectation de la demande n°' || NODEMANDE || ' à une tournée échouée.');
            DBMS_OUTPUT.PUT_LINE('Déplacement de la demande n°' || NODEMANDE || ' dans le journal des demandes à traiter.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Affectation de la demande n°' || NODEMANDE || ' échouée.');
        END IF;
    END;

---- Procédure de Déplacement d'une demande vers le journal des demandes à traiter
CREATE OR REPLACE PROCEDURE DEPLACEMENT_DEMANDE_VERS_DEMANDE_NON_TRAITEE(NUMDEMANDE INTEGER) AS
    dmd DEMANDE%ROWTYPE;
    BEGIN
       SELECT * INTO dmd FROM DEMANDE WHERE NODEMANDE = NUMDEMANDE;
       DELETE DEMANDE WHERE NODEMANDE = NUMDEMANDE;
       INSERT INTO DEMANDENONTRAITEE (NODEMANDE, DATEDEMANDE, DATEENLEVEMENT, WEB_O_N, SIRET, NOSITE)
       VALUES (dmd.NODEMANDE, dmd.DATEDEMANDE, dmd.DATEENLEVEMENT, dmd.WEB_O_N, dmd.SIRET, dmd.NOSITE);
    END;

---- Procédure affectant une demande à une tournée, dans le cas d'une demande non affectée uniquement
CREATE OR REPLACE PROCEDURE AFFECTATION_DEMANDE_TOURNEE(NUMDEMANDE INTEGER, NUMTOURNEE INTEGER) AS
    v_demande DEMANDE%ROWTYPE;
    BEGIN
        SELECT * INTO v_demande FROM DEMANDE WHERE NODEMANDE = NUMDEMANDE;
        IF v_demande.NOTOURNEE IS NULL THEN
            UPDATE DEMANDE SET NOTOURNEE = NUMTOURNEE WHERE NODEMANDE = v_demande.NODEMANDE;
        ELSE
            DBMS_OUTPUT.PUT_LINE('Cette demande est déjà affectée à une tournée, affectation impossible.');
        END IF;
    END;

---- Fonction retournant le nombre de tournées disponibles pour un site et une date donnée
CREATE OR REPLACE FUNCTION NOMBRE_TOURNEES_DISPONIBLES(NUMSITE INTEGER, DATET DATE) RETURN INTEGER AS
    v_nbTournees INTEGER := 0;
    CURSOR c_count IS
        SELECT COUNT(*) AS NBTOURNEES
        FROM TOURNEES_DISPONIBLES
        WHERE NOSITE = NUMSITE AND DATETOURNEE = DATET;
    BEGIN
       FOR c IN c_count
        LOOP
            v_nbTournees := v_nbTournees + c.NBTOURNEES;
        END LOOP;
       RETURN v_nbTournees;
    END;

-- Utilisation
BEGIN
    INSCRIPTION_DEMANDES_TOURNEES();
END;

----------------------------------------------------------------------------------------------
-- Vérification enregistrement dépôt de déchets dans un centre de traitement
----------------------------------------------------------------------------------------------

-- Trigger
CREATE OR REPLACE TRIGGER VERIF_QTE_DEPOSEE BEFORE INSERT ON DETAILDEPOT FOR EACH ROW
    DECLARE
        v_qtedeposee INTEGER := :new.QUANTITEDEPOSEE;
        v_max_quantite_deposable INTEGER := QUANTITE_RESTANTE_A_DEPOSER_TYPE_TOURNEE(:new.NOTOURNEE, :new.NOTYPEDECHET);
    BEGIN
        IF v_qtedeposee > v_max_quantite_deposable THEN
            raise_application_error(-20001, 'Dépôt impossible, la quantité déposée dépasse la quantité enlevée restante de la tournée pour ce type de déchet.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Le dépôt a bien été pris en compte');
        END IF;
    END;

-- Dépendances du trigger

---- Fonction retournant la quantité totale enlevée pour un type de déchet sur une tournée
CREATE OR REPLACE FUNCTION QUANTITE_ENLEVEE_TYPE_TOURNEE(NUMTOURNEE INTEGER, NUMTYPEDECHET INTEGER) RETURN INTEGER AS
    CURSOR c_enlevements IS
        SELECT DETAILDEMANDE.QUANTITEENLEVEE AS QTE
        FROM DETAILDEMANDE
            JOIN DEMANDE ON DEMANDE.NODEMANDE = DETAILDEMANDE.NODEMANDE
        WHERE DEMANDE.NOTOURNEE = NUMTOURNEE
            AND DETAILDEMANDE.NOTYPEDECHET = NUMTYPEDECHET;
    v_quantite INTEGER := 0;
    BEGIN
       FOR enlevement IN c_enlevements
           LOOP
               v_quantite := v_quantite + enlevement.QTE;
           END LOOP;
       RETURN v_quantite;
    END;

---- Fonction retournant la quantité restante à déposer pour un type de déchet sur une tournée
---- (différence entre la quantité totale enlevée moins la quantité totale déposée sur un centre)
CREATE OR REPLACE FUNCTION QUANTITE_RESTANTE_A_DEPOSER_TYPE_TOURNEE(NUMTOURNEE INTEGER, NUMTYPEDECHET INTEGER) RETURN INTEGER AS
    CURSOR c_depots IS
        SELECT DETAILDEPOT.QUANTITEDEPOSEE AS QTE
        FROM DETAILDEPOT
        WHERE DETAILDEPOT.NOTOURNEE = NUMTOURNEE
            AND DETAILDEPOT.NOTYPEDECHET = NUMTYPEDECHET;
    v_quantite INTEGER := QUANTITE_ENLEVEE_TYPE_TOURNEE(NUMTOURNEE, NUMTYPEDECHET);
    BEGIN
       FOR depot IN c_depots
           LOOP
               v_quantite := v_quantite - depot.QTE;
           END LOOP;
       RETURN v_quantite;
    END;