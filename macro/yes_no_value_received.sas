/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: yes_no_value_received.sas
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

%macro yes_no_value_received(parameter=) /minoperator;
	%let &parameter = %qsubstr(%qupcase(&&&parameter),1,1);		         
	%if ^%eval(&&&parameter in Y N) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Invalid selection for &parameter parameter.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Valid values are Y/N/YES/NO case insensitive.;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		0
		%return;
	%end;
	1
%mend yes_no_value_received;