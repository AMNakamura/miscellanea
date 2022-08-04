/*	******************************************************************
	MACRO NAME:	_connect.sas
	PURPOSE: 	Establish the ODBC connection to a database with a prompt 
            to prevent capturing usernames and passwords in the SAS
            script.
	WRITTEN BY: Ann Nakamura
	DATE:		April 2017
*********************************************************************/

%global user;

%Window getuser
  #7 @5 'Type the username, then press [ENTER]:'
  #7 @61 user 15 attr=underline display=yes 
  #11 @5 'Type the password, then press [ENTER]:'
  #11 @61 pw 25 attr=underline display=yes ;

%display getuser BELL;
	
	
LIBNAME mydb odbc dsn=DBNAME SCHEMA=SCHEMA_NAME user=&user password=&pw ;
