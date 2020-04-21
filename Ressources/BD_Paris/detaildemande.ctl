load data
   infile 	'c:\load\detaildemande.txt'
   badfile 	'c:\load\detaildemande.bad'
   discardfile 	'c:\load\detaildemande.dsc'
INSERT 
into table DETAILDEMANDE
fields terminated by ';' 
trailing nullcols ( QUANTITEENLEVEE,
		    NODEMANDE,
		    NOTYPEDECHET )
