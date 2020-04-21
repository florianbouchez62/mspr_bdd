load data
   infile 	'c:\load\marque.txt'
   badfile 	'c:\load\marque.bad'
   discardfile 	'c:\load\marque.dsc'
INSERT 
into table MARQUE
fields terminated by ';' 
trailing nullcols ( NOMARQUE   "seq_marque.nextval",
		    NOMMARQUE )
