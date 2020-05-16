-- =================================================================
-- Configuration de l'environnement de sauvegarde des données
-- (commandes à exécuter sur le serveur où est hébergée la base de
-- données)
-- =================================================================

-- Créer un dossier où sera placé le fichier de sauvegarde (ici /orabackup)
-- cd /
-- mkdir orabackup

-- Se connecter en tant que sysdba avec SQLPlus (remplacer passwd par le mdp sys)
-- sqlplus sys/passwd@localhost:1521/XEPDB1 as sysdba

-- Création du dossier où sera stocké le fichier de récupération du schéma et attribution des
-- privilèges (lecture/ecriture du dossier, export du schéma)
CREATE DIRECTORY schemas_backup AS '/orabackup';
GRANT READ, WRITE ON DIRECTORY schemas_backup TO rfrance;
GRANT DATAPUMP_EXP_FULL_DATABASE TO rfrance;

-- =================================================================
-- Sauvegarde du schéma
-- =================================================================

-- Fermer SQLPlus, et éxécuter la commande suivante pour exporter le schéma dans le dossier
-- /orabackup

-- expdp rfrance/rfrance@localhost:1521/XEPDB1 DIRECTORY=schemas_backup DUMPFILE=backup_rfrance.dmp LOGFILE=rfrance.log SCHEMAS=rfrance

-- =================================================================
-- Restauration du schéma
-- =================================================================

-- Exécuter les actions de suppression de la base corrompue mentionnées dans le fichier
-- del_recycl_france.sql (ne pas tout exécuter, juste ce qui est noté entre le début et
-- la fin du processus de restauration)

-- Exécuter la commande suivante pour importer le schéma sauvegardé depuis le dossier /orabackup
-- (connexion en sysdba requise)

-- impdp \"sys/passwd@localhost:1521/XEPDB1 as sysdba\" DIRECTORY=schemas_backup DUMPFILE=backup_rfrance.dmp
-- SCHEMAS=RFRANCE




