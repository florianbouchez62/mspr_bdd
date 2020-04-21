load data
   infile 	'c:\load\camion.txt'
   badfile 	'c:\load\camion.bad'
   discardfile 	'c:\load\camion.dsc'
INSERT 
into table CAMION
fields terminated by ';' 
trailing nullcols ( NOIMMATRIC,
		    DATEACHAT DATE "dd/mm/yyyy HH24:MI:SS",
		    MODELE,
		    MARQUE )
