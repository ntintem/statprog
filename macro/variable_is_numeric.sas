/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: variable_is_numeric.sas
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

%macro variable_is_numeric(data_in=
						  ,var_in=);
	%local dsid
		   var_type
		   rc;
	%let dsid=%sysfunc(open(&data_in));
	%let var_type = %sysfunc(vartype(&dsid, %sysfunc(varnum(&dsid, &var_in))));
	%let rc=%sysfunc(close(&dsid));
	%if &var_type = C %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Variable &var_in is not in the expected type.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Expected type is numeric.;
		%put ERROR:4/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		0
		%return;
	%end;
	1						
%mend variable_is_numeric;