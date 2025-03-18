/*
*****************************************************************************************************************
Project		 : StatProg
SAS file name: by_vars_are_valid.sas
File location: /statprog/macro/by_vars_are_valid.sas
*****************************************************************************************************************
Purpose: verifies if all variables passed to by_vars_in parameter exist
Author: Mazi Ntintelo
Creation Date: 2025-03-18
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro by_vars_are_valid;
	%local i;
	%do i=1 %to &by_vars_size;
		%let by_var&i=%scan(&by_vars_in, &i, #);
		%if ^%variable_exists(data_in=&data_in, var_in=&&by_var&i) %then %do;
			0
			%return;
		%end;
	%end;
	1
%mend by_vars_are_valid;