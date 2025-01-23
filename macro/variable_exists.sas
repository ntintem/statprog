/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: variable_exists.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get population counts from a dataset. Typically ADSL.
Author: Mazi Ntintelo
Creation Date: 2024-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro variable_exists(data_in=
					  ,var_in=);
	%local dsid
		   rc;
	%if ^%variable_name_is_valid(var_in=&var_in) %then %do;
		0
		%return;
	%end;
	%let dsid=%sysfunc(open(&data_in));
	%if ^%sysfunc(varnum(&dsid, &var_in)) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Variable &var_in not in &data_in data.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		%let rc=%sysfunc(close(&dsid));
		0
		%return;
	%end;
	%let rc=%sysfunc(close(&dsid));
	1
%mend variable_exists;