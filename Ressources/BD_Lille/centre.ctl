load data
   infile 	'c:\load\centre.txt'
   badfile 	'c:\load\centre.bad'
   discardfile 	'c:\load\centre.dsc'
INSERT 
into table CENTRETRAITEMENT
fields terminated by ';' 
trailing nullcols ( NOCENTRE   "seq_centre.nextval",
		    NOMCENTRE,
		    NORUECENTRE,
		    RUECENTRE,
		    CPOSTALCENTRE,
		    VILLECENTRE )
