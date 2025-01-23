/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: class_subgroups.sas
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

%macro class_subgroups;
	%local i;
	%do i=1 %to &subgroup_vars_size;
		class &&subgroup_var&i
		%if &&subgroup_format&i ne _NA_ %then %do;
			/preloadfmt exclusive
		%end;;
	%end;
%mend class_subgroups;