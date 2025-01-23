/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: subgroups.sas
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


%macro subgroups;
	%local i;
	%do i=1 %to &subgroup_vars_size;
		&&subgroup_var_&i
	%end;
%mend subgroups;