load data
   infile 	'c:\load\fonction.txt'
   badfile 	'c:\load\fonction.bad'
   discardfile 	'c:\load\fonction.dsc'
INSERT 
into table FONCTION
fields terminated by ';' 
trailing nullcols ( NOFONCTION,
		    NOMFONCTION )
