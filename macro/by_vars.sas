/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: by_vars.sas
File location: <path>
*****************************************************************************************************************
Purpose: Returns all by vars passed to by_vars_in parameter
Author: Mazi Ntintelo
Creation Date: 2023-06-30
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro by_vars;
	%local i;
	%do i=1 %to &by_vars_size;
		&&by_var&i
	%end;
%mend by_vars;