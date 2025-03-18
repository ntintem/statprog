/*
*****************************************************************************************************************
Project		 : StatProg
SAS file name: char_subgroups_array.sas
File location: /statprog/macro/char_subgroups_array.sas
*****************************************************************************************************************
Purpose: Macro returns a list of character subgroup variables
Author: Mazi Ntintelo
Creation Date: 2025-03-18
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/
%macro char_subgroups_array;
	%local i  
		   subgroup_char_vars_size;
	%let subgroup_char_vars_size=0;
	%do i=1 %to &subgroup_vars_size;
		%if %variable_type(data_in=&data_in,var_in=&&subgroup_var&i)=C %then %do;
			%let subgroup_char_vars_size=%eval(&subgroup_char_vars_size + 1);
			%let subgroup_char_var&subgroup_char_vars_size=&&subgroup_var&i;
		%end;
	%end;
%mend char_subgroups_array;