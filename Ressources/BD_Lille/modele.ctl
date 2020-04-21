load data
   infile 	'c:\load\modele.txt'
   badfile 	'c:\load\modele.bad'
   discardfile 	'c:\load\modele.dsc'
INSERT 
into table MODELE
fields terminated by ';' 
trailing nullcols ( NOMODELE  "seq_modele.nextval",
		    NOMMODELE,
		    NOMARQUE )
