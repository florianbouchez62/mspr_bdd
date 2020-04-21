load data
   infile 	'c:\load\tournee.txt'
   badfile 	'c:\load\tournee.bad'
   discardfile 	'c:\load\tournee.dsc'
INSERT 
into table TOURNEE
fields terminated by ';' 
trailing nullcols ( NOTOURNEE  "seq_tournee.nextval",
		    DATETOURNEE DATE "dd/mm/yyyy HH24:MI:SS",
		    NOIMMATRIC,
		    NOEMPLOYE )
