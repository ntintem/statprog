/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: variable_name_is_valid.sas
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

%macro variable_name_is_valid(var_in=);
	%if ^%sysfunc(prxmatch(%str(m/^[A-Za-z_]([A-Za-z_0-9]{1,31})?$/oi), &var_in)) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] data &var_in is not a valid SAS variable name.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		0
		%return;
	%end;
	1		
%mend variable_name_is_valid;