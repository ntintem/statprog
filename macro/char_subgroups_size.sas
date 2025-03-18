/*
*****************************************************************************************************************
Project		 : StatProg
SAS file name: char_subgroups_size.sas
File location: /statprog/macro/char_subgroups_size.sas
*****************************************************************************************************************
Purpose: Creating a summary by country and site
Author: Mazi Ntintelo
Creation Date: 2025-03-18
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro char_subgroups_size;
	%local i  
		   subgroup_char_vars_size;
	%let subgroup_char_vars_size=0;
	%do i=1 %to &subgroup_vars_size;
		%if %variable_type(data_in=&data_in,var_in=&&subgroup_var_&i)=C %then %let subgroup_char_vars_size=%eval(&subgroup_char_vars_size + 1);
	%end;
	&subgroup_char_vars_size
%mend char_subgroups_size;