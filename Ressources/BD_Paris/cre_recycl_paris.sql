connect system/xe

drop user rparis cascade;

create user rparis identified by rparis
default tablespace users;

grant connect, resource to rparis;

connect rparis/rparis

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

create table employe
(NoEmploye	 number(5) not null,
Nom		 varchar(50),
Prenom		 varchar(50),
dateNaiss	 date,
dateEmbauche	 date,
Salaire		 number(8,2),
Fonction	 varchar(50),
constraint PK_employe primary key(Noemploye)
);

create table typedechet
(NoTypeDechet	 number(3) not null,
NomTypeDechet	 varchar(50),
Niv_danger	 number(1),
constraint PK_typedechet primary key(Notypedechet)
);

create table camion
(NoImmatric	 char(10) not null,
DateAchat	 date,
Modele 		 varchar(50) not null,
Marque		 varchar(50) not null,
constraint PK_camion primary key(NoImmatric)
);


-- les tables avec FK 'simple'
-- ===========================
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
Web_O_N		 char(1),
Siret		 number(15) not null,
NoTournee	 number(6) null,
constraint PK_demande primary key(Nodemande),
constraint FK_demande_entreprise foreign key (Siret) references entreprise(Siret),
constraint FK_demande_tournee foreign key (notournee) references tournee(notournee)
);


-- les tables avec FK/PK
-- =====================

create table detaildemande
(QuantiteEnlevee	 number(3) not null,
NoDemande		 number(6) not null,
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


-- création de séquences
create sequence seq_typedechet start with 1 increment by 1;
create sequence seq_centre start with 1 increment by 1;
create sequence seq_employe start with 1 increment by 1;
create sequence seq_tournee start with 1 increment by 1;
create sequence seq_demande start with 1 increment by 1;



