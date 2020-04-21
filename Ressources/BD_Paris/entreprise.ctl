load data
   infile 	'c:\load\entreprise.txt'
   badfile 	'c:\load\entreprise.bad'
   discardfile 	'c:\load\entreprise.dsc'
INSERT 
into table ENTREPRISE 
fields terminated by ';' 
trailing nullcols ( SIRET,
		    RAISONSOCIALE,
		    NORUEENTR,
		    RUEENTR,
		    CPOSTALENTR,
		    VILLEENTR,
		    NOTEL,
		    CONTACT )
