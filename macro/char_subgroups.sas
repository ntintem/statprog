/*
*****************************************************************************************************************
Project		 : StatProg
SAS file name: char_subgroups.sas
File location: /statprog/macro/char_subgroups.sas
*****************************************************************************************************************
Purpose: Macro returns the list of character type subgroup variables passed to subgroup subgroup_vars_in parameter
Author: Mazi Ntintelo
Creation Date: 2025-01-23
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro char_subgroups;
	%local i;
	%do i=1 %to &subgroup_char_vars_size;
		&&subgroup_char_var&i
	%end;
%mend char_subgroups;
