load data
   infile 	'c:\load\demande.txt'
   badfile 	'c:\load\demande.bad'
   discardfile 	'c:\load\demande.dsc'
INSERT 
into table DEMANDE
fields terminated by ';' 
trailing nullcols ( NODEMANDE  "seq_demande.nextval",
		    DATEDEMANDE DATE "dd/mm/yyyy HH24:MI:SS",
		    DATEENLEVEMENT DATE "dd/mm/yyyy HH24:MI:SS",
		    WEB_O_N,
		    SIRET,
		    NOTOURNEE )
