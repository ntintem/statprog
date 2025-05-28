/*
*****************************************************************************************************************
Project		 : StatProg
SAS file name: internal_derived_variable_exists.sas
File location: /statprog/macro/internal_derived_variable_exists.sas
*****************************************************************************************************************
Purpose: Macro function used to verify the existence of an internally derived variable. Errors if variable exists.
Author: Mazi Ntintelo
Creation Date: 2025-05-28
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro internal_derived_variable_exists(data_in=
									   ,var_in=);
	
	%local dsid
		   rc;
	%if ^%variable_name_is_valid(var_in=&var_in) %then %do;
		1
		%return;
	%end;
	%let dsid=%sysfunc(open(&data_in));
	%if %sysfunc(varnum(&dsid, &var_in)) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Variable &var_in already in &data_in data.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		%let rc=%sysfunc(close(&dsid));
		1
		%return;
	%end;
	%let rc=%sysfunc(close(&dsid));
	0							
%mend internal_derived_variable_exists;