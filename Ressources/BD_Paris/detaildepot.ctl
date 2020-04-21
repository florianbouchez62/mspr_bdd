load data
   infile 	'c:\load\detaildepot.txt'
   badfile 	'c:\load\detaildepot.bad'
   discardfile 	'c:\load\detaildepot.dsc'
INSERT 
into table DETAILDEPOT
fields terminated by ';' 
trailing nullcols ( QUANTITEDEPOSEE,
		    NOTOURNEE,
		    NOTYPEDECHET,
		    NOCENTRE )
