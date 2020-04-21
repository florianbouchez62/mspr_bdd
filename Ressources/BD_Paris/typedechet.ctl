load data
   infile 	'c:\load\typedechet.txt'
   badfile 	'c:\load\typedechet.bad'
   discardfile 	'c:\load\typedechet.dsc'
INSERT 
into table TYPEDECHET
fields terminated by ';' 
trailing nullcols ( NOTYPEDECHET   "seq_typedechet.nextval",
		    NOMTYPEDECHET,
		    NIV_DANGER )
