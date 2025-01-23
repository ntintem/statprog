/*
*****************************************************************************************************************
Project		 : Open TLF
SAS file name: total_groups.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get population counts from a dataset. Typically ADSL.
Author: Mazi Ntintelo
Creation Date: 2023-06-30
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/



%macro total_groups;
	%local i;
	%do i=1 %to &total_groups_size;
		if &treatment_var_in in (&&total_group&i._condition) then do;
			_&treatment_var_in=&treatment_var_in;
			&treatment_var_in=&&total_group&i._value;
			output;
			&treatment_var_in=_&treatment_var_in;
		end;
	%end;
%mend total_groups;