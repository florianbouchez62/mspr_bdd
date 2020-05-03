-- ==================
-- Création tablespace et user RFRANCE, sur SQLPlus (se connecter en SYSDBA)
-- ==================

-- Montre les tablespaces existants
-- ==================
select tablespace_name from dba_tablespaces;

-- Création de la tablespace RFRANCE
-- ==================
create tablespace rfrance_tablespace
datafile 'rfrance_tablespace.dat'
size 100M autoextend on;

-- Création de la tablespace temporaire RFRANCE
-- ==================
create temporary tablespace rfrance_tablespace_temp
tempfile 'rfrance_tablespace_temp.dat'
size 10M autoextend on;

-- Création de l'utilisateur RFRANCE
-- ==================
create user rfrance
identified by rfrance
default tablespace rfrance_tablespace
temporary tablespace rfrance_tablespace_temp;

-- Attribution des privilèges
-- ==================
grant create session to rfrance;
grant create table to rfrance;
grant create view to rfrance;
grant create sequence to rfrance;
grant create procedure to rfrance;
grant create trigger to rfrance;
grant unlimited tablespace to rfrance;


-- Accès aux tables RLILLE, RPARIS
grant select on rlille.CAMION to rfrance;
grant select on rlille.CENTRETRAITEMENT to rfrance;
grant select on rlille.DEMANDE to rfrance;
grant select on rlille.DETAILDEMANDE to rfrance;
grant select on rlille.DETAILDEPOT to rfrance;
grant select on rlille.EMPLOYE to rfrance;
grant select on rlille.ENTREPRISE to rfrance;
grant select on rlille.FONCTION to rfrance;
grant select on rlille.TOURNEE to rfrance;
grant select on rlille.TYPEDECHET to rfrance;

grant select on rparis.CAMION to rfrance;
grant select on rparis.CENTRETRAITEMENT to rfrance;
grant select on rparis.DEMANDE to rfrance;
grant select on rparis.DETAILDEMANDE to rfrance;
grant select on rparis.DETAILDEPOT to rfrance;
grant select on rparis.EMPLOYE to rfrance;
grant select on rparis.ENTREPRISE to rfrance;
grant select on rparis.TOURNEE to rfrance;
grant select on rparis.TYPEDECHET to rfrance;

-- Visualiser les privilèges de l'utilisateur (se connecter en RFRANCE)
-- ==================
select * from session_privs;

-- ==================
-- Création des tables et séquences
-- ==================

-- les tables sans FK
-- ==================
create table entreprise
(Siret		 number(15) not null,
RaisonSociale	 varchar(50) not null,
NoRueEntr	 number(3),
RueEntr		 varchar(200),
CpostalEntr	 number(5),
VilleEntr	 varchar(50),
NoTel		 char(10),
Contact		 varchar(50),
constraint PK_entreprise primary key(Siret)
);

create table centretraitement
(NoCentre	 number(3) not null,
NomCentre	 varchar(100),
NoRueCentre	 number(3),
RueCentre	 varchar(200),
CpostalCentre	 number(5),
VilleCentre	 varchar(50),
constraint PK_centretraitement primary key(Nocentre)
);

create table fonction
(NoFonction	 number(3) not null,
NomFonction	 varchar(50) not null,
constraint PK_fonction primary key(NoFonction)
);

create table typedechet
(NoTypeDechet	 number(3) not null,
NomTypeDechet	 varchar(50),
Niv_danger	 number(1),
MaxVolumeForfaitaire varchar(20) null,
TarifForfaitaire number(8,2) null,
VolumeLot varchar(20) null,
TarifLot number(8,2) null,
constraint PK_typedechet primary key(Notypedechet)
);

create table site
(NoSite number(3) not null,
NomSite varchar(50) not null,
NoRueSite number(3) not null,
RueSite varchar(200) not null,
CPostalSite number(5) not null,
VilleSite varchar(50) not null,
NoTelSite char(10) not null,
ContactSite varchar(50) not null,
constraint PK_nosite primary key (NoSite)
);

-- les tables avec FK 'simple'
-- ===========================
create table employe
(NoEmploye	 number(5) not null,
Nom		 varchar(50),
Prenom		 varchar(50),
Username char(6) UNIQUE,
dateNaiss	 date,
dateEmbauche	 date,
Salaire		 number(8,2),
NoFonction	 number(3),
NoSite number(3),
constraint PK_employe primary key(Noemploye),
constraint FK_employe_nofonction foreign key (nofonction) references fonction(nofonction),
constraint FK_employe_nosite foreign key (nosite) references site(nosite)
);

-- Trigger empêchant la modification du nom d'utilisateur
create trigger not_editable_username before update on employe for each row
declare
begin
    if(:new.Username != :old.Username) then
        raise_application_error(-20001, 'La modification du nom utilisateur est impossible.');
    end if;
end;

create table camion
(NoImmatric	 char(10) not null,
DateAchat	 date,
Modele 		 varchar(50) not null,
Marque		 varchar(50) not null,
MaxEnlevements number(2) default 5 not null,
NoSite number(3),
constraint PK_camion primary key(NoImmatric),
constraint FK_camion_site foreign key (nosite) references site(nosite)
);

create table tournee
(NoTournee	 number(6) not null,
DateTournee	 date,
NoImmatric	 char(10) not null,
NoEmploye	 number(5) not null,
constraint PK_tournee primary key(Notournee),
constraint FK_tournee_camion foreign key (NoImmatric) references camion(noImmatric),
constraint FK_tournee_employe foreign key (noemploye) references employe(noemploye)
);

create table demande
(NoDemande	 number(6) not null,
DateDemande	 date,
DateEnlevement	 date,
Web_O_N char(1),
Siret		 number(15) not null,
NoTournee	 number(6) null,
NoSite number(3) not null,
constraint PK_demande primary key(Nodemande),
constraint FK_demande_entreprise foreign key (Siret) references entreprise(Siret),
constraint FK_demande_tournee foreign key (notournee) references tournee(notournee),
constraint FK_demande_nosite foreign key (NoSite) references  site(NoSite)
);

create table demandenontraitee
(NoDemande number(6) not null,
DateDemande date,
DateEnlevement date,
Web_O_N char(1),
Siret number(15) not null,
NoSite number(3) not null,
constraint PK_demande_non_traitee primary key (Nodemande),
constraint FK_demande_non_traitee_entreprise foreign key (Siret) references entreprise(Siret),
constraint FK_demande_non_traitee_nosite foreign key (NoSite) references site(NoSite)
);


-- les tables avec FK/PK
-- =====================

create table detaildemande
(QuantiteEnlevee	 number(3) not null,
NoDemande		 number(6) not null,
Remarque varchar(100) null,
NoTypeDechet		 number(3) not null,
constraint PK_detaildemande primary key(Nodemande, notypedechet),
constraint FK_detaildem_demande foreign key (NoDemande) references demande(NoDemande),
constraint FK_detaildem_typedech foreign key (notypedechet) references typedechet(notypedechet)
);

create table detaildepot
(QuantiteDeposee	 number(3) not null,
NoTournee		 number(6) not null,
NoTypeDechet		 number(3) not null,
NoCentre		 number(3) not null,
constraint PK_detaildepot primary key(Notournee, notypedechet, nocentre),
constraint FK_detaildep_tournee foreign key (NoTournee) references tournee(NoTournee),
constraint FK_detaildep_typedech foreign key (notypedechet) references typedechet(notypedechet),
constraint FK_detaildep_centre foreign key (NoCentre) references centretraitement(NoCentre)
);


-- cr�ation de s�quences
create sequence seq_typedechet start with 1 increment by 1;
create sequence seq_centre start with 1 increment by 1;
create sequence seq_employe start with 1 increment by 1;
create sequence seq_tournee start with 1 increment by 1;
create sequence seq_demande start with 1 increment by 1;
create sequence seq_site start with 1 increment by 1;

-- Connect to remote database with sqlplus
-- sqlplus sys/passwd@217.182.171.102:1521/XEPDB1 as sysdba