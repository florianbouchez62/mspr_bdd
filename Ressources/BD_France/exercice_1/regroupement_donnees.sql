-- Script à éxécuter en tant que RFRANCE (vérifier que l'utilisateur possède les permissions de select sur RLILLE et
-- RPARIS)

-- > ENTREPRISE
INSERT INTO RFRANCE.ENTREPRISE(SIRET, RAISONSOCIALE, NORUEENTR, RUEENTR, CPOSTALENTR, VILLEENTR, NOTEL, CONTACT)
SELECT * FROM RPARIS.ENTREPRISE
UNION
SELECT * FROM RLILLE.ENTREPRISE;
-- < ENTREPRISE

-- > CENTRETRAITEMENT
DECLARE
    CURSOR c_centres IS
        SELECT NOMCENTRE, NORUECENTRE, RUECENTRE, CPOSTALCENTRE, VILLECENTRE FROM RPARIS.CENTRETRAITEMENT
        UNION
        SELECT NOMCENTRE, NORUECENTRE, RUECENTRE, CPOSTALCENTRE, VILLECENTRE FROM RLILLE.CENTRETRAITEMENT;
BEGIN
    FOR centre IN c_centres
        LOOP
            INSERT INTO CENTRETRAITEMENT (NOCENTRE, NOMCENTRE, NORUECENTRE, RUECENTRE, CPOSTALCENTRE, VILLECENTRE)
            VALUES(SEQ_CENTRE.nextval, centre.NOMCENTRE, centre.NORUECENTRE, centre.RUECENTRE, centre.CPOSTALCENTRE, centre.VILLECENTRE);
        END LOOP;
END;
-- < CENTRETRAITEMENT

-- > FONCTION
INSERT INTO FONCTION (NOFONCTION, NOMFONCTION)
SELECT NOFONCTION, NOMFONCTION FROM RLILLE.FONCTION;
-- < FONCTION

-- > TYPE DECHET
INSERT INTO TYPEDECHET(notypedechet, nomtypedechet, niv_danger)
SELECT notypedechet, nomtypedechet, niv_danger FROM RLILLE.TYPEDECHET;
-- < TYPE DECHET

-- > SITE
INSERT INTO SITE(NOSITE, NOMSITE, NORUESITE, RUESITE, CPOSTALSITE, VILLESITE, NOTELSITE, CONTACTSITE) VALUES
(1, 'RECYCL LILLE', 1, 'Avenue du Recyclage', 59000, 'Lille', '0302010302', 'dirk.anderson@recycl-lille.fr');

INSERT INTO SITE(NOSITE, NOMSITE, NORUESITE, RUESITE, CPOSTALSITE, VILLESITE, NOTELSITE, CONTACTSITE) VALUES
(2, 'RECYCL PARIS', 1, 'Boulevard du Recyclage', 75000, 'Paris', '0103010302', 'simon.daniel@recycl-paris.fr');
-- < SITE

-- > CAMION
DECLARE
    CURSOR c_camions_lille IS
        SELECT NOIMMATRIC, DATEACHAT, MODELE, MARQUE FROM RLILLE.CAMION;
    CURSOR c_camions_paris IS
        SELECT NOIMMATRIC, DATEACHAT, MODELE, MARQUE FROM RPARIS.CAMION;
BEGIN
    FOR camion IN c_camions_lille
        LOOP
            INSERT INTO CAMION (NOIMMATRIC, DATEACHAT, MODELE, MARQUE, NOSITE)
            VALUES (camion.NOIMMATRIC, camion.DATEACHAT, camion.MODELE, camion.MARQUE, 1);
        END LOOP;
    FOR camion IN c_camions_paris
        LOOP
            INSERT INTO CAMION (NOIMMATRIC, DATEACHAT, MODELE, MARQUE, NOSITE)
            VALUES (camion.NOIMMATRIC, camion.DATEACHAT, camion.MODELE, camion.MARQUE, 2);
        END LOOP;
END;
-- < CAMION

-- > EMPLOYE && TOURNEE && DEMANDE && DETAILDEMANDE && DETAILDEPOT
DECLARE
    CURSOR c_empl_lille IS
        SELECT NOEMPLOYE, NOM, PRENOM, DATENAISS, DATEEMBAUCHE, SALAIRE, EMPLOYE.NOFONCTION, NOMFONCTION
        FROM RLILLE.EMPLOYE JOIN RLILLE.FONCTION ON EMPLOYE.NOFONCTION = FONCTION.NOFONCTION;
    CURSOR c_empl_paris IS
        SELECT NOEMPLOYE, NOM, PRENOM, DATENAISS, DATEEMBAUCHE, SALAIRE, FONCTION
        FROM RPARIS.EMPLOYE;
    CURSOR unaffected_demande_lille IS
        SELECT * FROM RLILLE.DEMANDE WHERE NOTOURNEE IS NULL;
    CURSOR unaffected_demande_paris IS
        SELECT * FROM RPARIS.DEMANDE WHERE NOTOURNEE IS NULL;
    v_numFonction number;
    v_numCentre number;
    v_username varchar(6);
BEGIN
    FOR empl IN c_empl_lille
        LOOP
            v_username := UPPER(SUBSTR(empl.PRENOM, 1, 1) || SUBSTR(empl.NOM, 1, 3));
            IF empl.NOMFONCTION = 'directeur' THEN
                v_username := 'D_' || v_username;
            ELSIF empl.NOMFONCTION = 'responsable' THEN
                v_username := 'R_' || v_username;
            ELSIF empl.NOMFONCTION = 'commercial' OR empl.NOMFONCTION = 'secr�taire' THEN
                v_username := 'A_' || v_username;
            ELSE
                v_username := 'E_' || v_username;
            END IF;
            INSERT INTO EMPLOYE (NOEMPLOYE, NOM, PRENOM, USERNAME, DATENAISS, DATEEMBAUCHE, SALAIRE, NOFONCTION, NOSITE)
            VALUES (SEQ_EMPLOYE.nextval, empl.NOM, empl.PRENOM, v_username, empl.DATENAISS, empl.DATEEMBAUCHE, empl.SALAIRE, empl.NOFONCTION, 1);

            FOR t IN (SELECT * FROM RLILLE.TOURNEE WHERE NOEMPLOYE = empl.NOEMPLOYE)
                LOOP
                    INSERT INTO TOURNEE (NOTOURNEE, DATETOURNEE, NOIMMATRIC, NOEMPLOYE)
                    VALUES(SEQ_TOURNEE.nextval, t.DATETOURNEE, t.NOIMMATRIC, SEQ_EMPLOYE.currval);
                    FOR d IN (SELECT * FROM RLILLE.DEMANDE WHERE NOTOURNEE = t.NOTOURNEE)
                        LOOP
                            INSERT INTO DEMANDE(NODEMANDE, DATEDEMANDE, DATEENLEVEMENT, SIRET, NOTOURNEE, NOSITE)
                            VALUES (SEQ_DEMANDE.nextval, d.DATEDEMANDE, d.DATEENLEVEMENT, d.SIRET, SEQ_TOURNEE.currval, 1);
                            FOR detailDem IN (SELECT * FROM RLILLE.DETAILDEMANDE WHERE NODEMANDE = d.NODEMANDE)
                                LOOP
                                    INSERT INTO DETAILDEMANDE(QUANTITEENLEVEE, REMARQUE, NODEMANDE, NOTYPEDECHET)
                                    VALUES(detailDem.QUANTITEENLEVEE, detailDem.REMARQUE, SEQ_DEMANDE.currval, detailDem.NOTYPEDECHET);
                                END LOOP;
                        END LOOP;
                    FOR detailDep IN (SELECT * FROM RLILLE.DETAILDEPOT JOIN RLILLE.CENTRETRAITEMENT
                        ON RLILLE.DETAILDEPOT.NOCENTRE = RLILLE.CENTRETRAITEMENT.NOCENTRE WHERE NOTOURNEE = t.NOTOURNEE)
                        LOOP
                            SELECT NOCENTRE INTO v_numCentre FROM CENTRETRAITEMENT
                            WHERE NOMCENTRE = detailDep.NOMCENTRE AND CPOSTALCENTRE = detailDep.CPOSTALCENTRE;
                            INSERT INTO DETAILDEPOT(QUANTITEDEPOSEE, NOTOURNEE, NOTYPEDECHET, NOCENTRE)
                            VALUES (detailDep.QUANTITEDEPOSEE, SEQ_TOURNEE.currval, detailDep.NOTYPEDECHET, v_numCentre);
                        END LOOP;
                END LOOP;
        END LOOP;

    FOR dmd IN unaffected_demande_lille
            LOOP
                INSERT INTO DEMANDE(NODEMANDE, DATEDEMANDE, DATEENLEVEMENT, SIRET, NOSITE)
                VALUES (SEQ_DEMANDE.nextval, dmd.DATEDEMANDE, dmd.DATEENLEVEMENT, dmd.SIRET, 1);
            END LOOP;

    FOR empl IN c_empl_paris
        LOOP
            v_username := UPPER(SUBSTR(empl.PRENOM, 1, 1) || SUBSTR(empl.NOM, 1, 3));
            IF empl.FONCTION = 'directeur' THEN
                v_username := 'D_' || v_username;
            ELSIF empl.FONCTION = 'responsable' THEN
                v_username := 'R_' || v_username;
            ELSIF empl.FONCTION = 'commercial' OR empl.FONCTION = 'secr�taire' THEN
                v_username := 'A_' || v_username;
            ELSE
                v_username := 'E_' || v_username;
            END IF;
            SELECT NOFONCTION INTO v_numFonction FROM FONCTION WHERE NOMFONCTION = empl.FONCTION;
            INSERT INTO EMPLOYE (NOEMPLOYE, NOM, PRENOM, USERNAME, DATENAISS, DATEEMBAUCHE, SALAIRE, NOFONCTION, NOSITE)
            VALUES (SEQ_EMPLOYE.nextval, empl.NOM, empl.PRENOM, v_username, empl.DATENAISS, empl.DATEEMBAUCHE, empl.SALAIRE, v_numFonction, 2);
            FOR t IN (SELECT * FROM RPARIS.TOURNEE WHERE NOEMPLOYE = empl.NOEMPLOYE)
                LOOP
                    INSERT INTO TOURNEE (NOTOURNEE, DATETOURNEE, NOIMMATRIC, NOEMPLOYE)
                    VALUES(SEQ_TOURNEE.nextval, t.DATETOURNEE, t.NOIMMATRIC, SEQ_EMPLOYE.currval);
                    FOR d IN (SELECT * FROM RPARIS.DEMANDE WHERE NOTOURNEE = t.NOTOURNEE)
                        LOOP
                            INSERT INTO DEMANDE(NODEMANDE, DATEDEMANDE, DATEENLEVEMENT, WEB_O_N, SIRET, NOTOURNEE, NOSITE)
                            VALUES (SEQ_DEMANDE.nextval, d.DATEDEMANDE, d.DATEENLEVEMENT, d.WEB_O_N , d.SIRET, SEQ_TOURNEE.currval, 2);
                            FOR detailDem IN (SELECT * FROM RPARIS.DETAILDEMANDE WHERE NODEMANDE = d.NODEMANDE)
                                LOOP
                                    INSERT INTO DETAILDEMANDE(QUANTITEENLEVEE, REMARQUE, NODEMANDE, NOTYPEDECHET)
                                    VALUES(detailDem.QUANTITEENLEVEE, null, SEQ_DEMANDE.currval, detailDem.NOTYPEDECHET);
                                END LOOP;
                        END LOOP;
                    FOR detailDep IN (SELECT * FROM RPARIS.DETAILDEPOT JOIN RPARIS.CENTRETRAITEMENT
                        ON RPARIS.DETAILDEPOT.NOCENTRE = RPARIS.CENTRETRAITEMENT.NOCENTRE WHERE NOTOURNEE = t.NOTOURNEE)
                        LOOP
                            SELECT NOCENTRE INTO v_numCentre FROM CENTRETRAITEMENT
                            WHERE NOMCENTRE = detailDep.NOMCENTRE AND CPOSTALCENTRE = detailDep.CPOSTALCENTRE;
                            INSERT INTO DETAILDEPOT(QUANTITEDEPOSEE, NOTOURNEE, NOTYPEDECHET, NOCENTRE)
                            VALUES (detailDep.QUANTITEDEPOSEE, SEQ_TOURNEE.currval, detailDep.NOTYPEDECHET, v_numCentre);
                        END LOOP;

                END LOOP;
        END LOOP;

    FOR dmd IN unaffected_demande_paris
        LOOP
            INSERT INTO DEMANDE(NODEMANDE, DATEDEMANDE, DATEENLEVEMENT, WEB_O_N, SIRET, NOSITE)
            VALUES (SEQ_DEMANDE.nextval, dmd.DATEDEMANDE, dmd.DATEENLEVEMENT, dmd.WEB_O_N, dmd.SIRET, 2);
        END LOOP;
END;
-- < EMPLOYE && TOURNEE && DEMANDE && DETAILDEMANDE && DETAILDEPOT
