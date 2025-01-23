/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: dataset_name_is_valid.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating a summary by country and site
Author: Mazi Ntintelo
Creation Date: 2024-09-18
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro dataset_name_is_valid(data_in=);						   
	%local libref;
	%if %sysfunc(prxmatch(%str(m/^[A-Za-z_][A-Za-z_0-9]{1,7}[.][A-Za-z_]([A-Za-z_0-9]{1,31})?$/oi), &data_in)) %then %do;
		%let libref=%scan(&data_in, 1, .);
		%if ^%library_exists(libref=&libref) %then %do;
	 		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] &data_in is a valid SAS 2 level name, however libref &libref is not assigned.;
			%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
			0
			%return;
		%end;
	%end;
	%else %if ^%sysfunc(prxmatch(%str(m/^[A-Za-z_]([A-Za-z_0-9]{1,31})?$/oi), &data_in)) %then %do;
	 	%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] data &data_in is not a valid SAS dataset name.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		0
		%return;
	%end;	
	1						   
%mend dataset_name_is_valid;