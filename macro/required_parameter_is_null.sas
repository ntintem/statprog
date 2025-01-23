/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: required_parameter_is_null.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating a summary by country and site
Author: Mazi Ntintelo
Creation Date: 2025-01-23
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro required_parameter_is_null(parameter=);
	%if %sysevalf(%superq(&parameter)=, boolean) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Parameter &parameter is required.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		1
		%return;
	%end;
	0
%mend required_parameter_is_null;