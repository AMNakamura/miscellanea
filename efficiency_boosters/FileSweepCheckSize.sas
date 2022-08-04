/* ***************************************************************************
	Program:	FileSweepCheckSize.SAS
	Purpose:	Documentation discovery
				Create a directory listing of files in folders and subfolders
				and scan the directory for files with certain characteristics
				and copy a selected set of files to a network folder.

	Written	by: Ann Nakamura
	Date:		Orig. 6/1/2012 - Updated for NEW project 11/22/2017
				FileSweepCopyToNetworkFldrs.SAS
	
	Resource: 	(New) https://www.sas.com/content/dam/SAS/en_ca/User%20Group%20Presentations/
				TASS/Jia_Lin_Manage_External_Files_June2015.pdf
*  ************************************************************************* */

* Step1. Get files from filestore (simple method).;
* Use the /s option to recurse subdirectories and list their contents as well. Tested in DOS 12/16/2019 on the 
  R directory.;

* Test in DOS command prompt first.;
FILENAME D Pipe 'dir "K:\myfldr\" /s';
%LET SrcPath=%str(K:\myfldr\);

DATA DLIST;
	
	LENGTH buffer $256 ;
	INFILE D LENGTH =reclen truncover;
	
	INPUT buffer $varying256. reclen ;

		MODATE 	 = INPUT(scan(buffer,1,' '),mmddyy10.);
		MOTIME1	 = scan(buffer,2,' ');
		MOTIME2  = scan(buffer,3,' ');
		BYTES 	 = scan(buffer,4,' ');
		FileName = scan(buffer,5,' ');

		FORMAT MODATE mmddyy10.;
		IF MODATE EQ . OR FileName IN('.','..') THEN DELETE;
	
	RUN; 

PROC SORT DATA=Dlist1; BY DESCENDING SZ; RUN; 

* Quick inspection;

PROC SQL;
	CREATE TABLE ExtSizeAgg AS 
		SELECT DISTINCT Ext, ROUND(MIN(sz),1) AS szMin,
							 ROUND(MAX(sz),1) AS szMax,
							 ROUND(MEAN(sz),1) AS sxMean
							 FROM DLIST1
							 GROUP BY Ext;
							 	QUIT; 

PROC SORT DATA=ExtSizeAgg; BY DESCENDING SzMAX;
RUN; 

%MACRO GetBigFiles(extension,db);

	PROC SQL;  CREATE TABLE &extension AS 
				SELECT buffer, modate, bytes, filename, ext, sz
					FROM Dlist1 WHERE EXT EQ %tslit(&extension) 
						ORDER BY sz DESC; QUIT; 
%MEND;

%GetBigFiles(ppt); * Removed visualizing tests ppt;
%GetBigFiles(pdf); * Removed psyc overview.pdf, MacroEnableRProgrammingNative.pdf;
%GetBigFiles(html);

%macro list_files(dir,ext);
  %local filrf rc did memcnt name i;
  %let rc=%sysfunc(filename(filrf,&dir));
  %let did=%sysfunc(dopen(&filrf));      

   %if &did eq 0 %then %do; 
    %put Directory &dir cannot be open or does not exist;
    %return;
  %end;

   %do i = 1 %to %sysfunc(dnum(&did));   

   %let name=%qsysfunc(dread(&did,&i));

      %if %qupcase(%qscan(&name,-1,.)) = %upcase(&ext) %then %do;
        %put &dir\&name;

        data _tmp;
          length dir $512 name $100;
          dir=symget("dir");
          name=symget("name");
		  /* added */
		  fid=fopen(&name); 
     	  dte=finfo(&name,'Last Modified');                                                                                                     
		  size=finfo(&name,'File Size (bytes)');   
		 
        run;
        proc append base=want data=_tmp;
        run;quit;

      %end;
      %else %if %qscan(&name,2,.) = %then %do;        
        %list_files(&dir\&name,&ext)
      %end;

   %end;
   %let rc=%sysfunc(dclose(&did));
   %let rc=%sysfunc(filename(filrf));     

%mend list_files;


%list_files(k:\NEW\DataDev,sas);

%macro getFileSizes (directory, extension, dataSet);                                                                                                                   

data &dataSet(drop=fid ff filrfb rc); 

%let bb=%sysfunc(filename(filrf,&directory));

%let did=%sysfunc(dopen(&filrf));

%let flname=;

%let memcount=%sysfunc(dnum(&did));

%if &memcount > 0 %then %do i=1 %to &memcount;

    %let flname&i=%qsysfunc(dread(&did,&i));

  %if %scan(&&flname&i,-1,.) = &extension or &extension = all %then %do;

     filrfb='temp';

     ff=filename(filrfb,"&directory\&&flname&i"); 

     fid=fopen(filrfb); 

     dte=finfo(fid,'Last Modified');                                                                                                     

     size=finfo(fid,'File Size (bytes)');                                                                                                 

	 output;  

     rc=fclose(fid);      

  %end;

%end;   

%let rc=%sysfunc(dclose(&did));  

run;

%mend;

%getFileSizes(k:\NEW\DataDev,all,GotFiles);


%macro test(mydir);                                                                                                                   

data want(drop=fid ff filrfb rc);                                                                                             

%let bb=%sysfunc(filename(filrf,&mydir));                                                                                             

%let did=%sysfunc(dopen(&filrf));                                                                                                     

%let flname=;                                                                                                                         

%let memcount=%sysfunc(dnum(&did));                                                                                                   

%if &memcount > 0 %then %do;                                                                                                           

  %do i=1 %to &memcount;                                                                                                             

  %let flname&i=%qsysfunc(dread(&did,&i));                                                                                             

  filrfb='temp';                                                                                                                     

  ff=filename(filrfb,"&mydir\&&flname&i");                                                                                           

  fid=fopen(filrfb);                                                                                                                 

  dte=finfo(fid,'Last Modified');                                                                                                     

  size=finfo(fid,'File Size (bytes)');                                                                                                 

  file=symget("flname&i");                                                                                                             

  output;                                                                                                                             

rc=fclose(fid);                                                                                                                       

  %end; %end;                                                                                                                         

%let rc=%sysfunc(dclose(&did));                                                                                                       

run;                                                                                                                                   

%mend;                                                                                                                                 

%test(k:\NEW\DataDev);
