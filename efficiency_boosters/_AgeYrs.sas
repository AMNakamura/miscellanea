/*	******************************************************************
	MACRO NAME:	_AgeYrs.sas
	PURPOSE: 	Calculate a person's age, in years, between two dates. 
	WRITTEN BY: Ann Nakamura
	DATE:		April 2003
*********************************************************************/

%MACRO ageYrs(d1,d2);

IF NOT(&d1 eq . OR &d2 eq .) THEN DO;
/* First, determine number of days in the month prior to d2 month. */
	   lmodays=day(intnx('month',&d2,0)-1); 

/* Next, use subtraction by day, month, and year to calculate the days,
   months, and years between dates of birth and death. */
       dd = DAY(&d2)   - DAY(&d1);	
	   mm = MONTH(&d2) - MONTH(&d1);
	   yy = YEAR(&d2)  - YEAR(&d1); 

/* If the difference in days is a negative value, add the number 
   of days in the previous month and reduce the number of months 
   by 1.                                                         */
  		if dd < 0 then do;
    		dd=lmodays+dd;
    		mm=mm-1;
  		end;	
  
  /* If the difference in months is a negative number add 12 
     to the number of months and subtract a year from the number of years. */
  		if mm < 0 then do;
    		mm=mm+12;
    		yy=yy-1;
  		end;
 END;  
 drop mm dd lmodays;
%MEND;				
