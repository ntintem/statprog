/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: total_groups_definition_is_valid.sas
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


%macro total_groups_definition_is_valid;
	%local i;
	%do i=1 %to &total_groups_size;
		%let total_group&i = %scan(&define_total_groups, &i, #);
		%if ^%sysfunc(prxmatch(%str(m/^\d+\s+\d+(\s+\d+)*\s*=\s*\d+$/oi), %superq(total_group&i))) %then %do; 
			%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Pattern &&total_group&i is invalid pattern for totals definition;
			%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Expecting a pattern in the following form: Treatment ID + Treatment ID = _NEW_ Treatment ID;
			%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
			0
			%return;
		%end;
		%let total_group&i._condition = %scan(&&total_group&i, 1, =);
		%let total_group&i._value = %scan(&&total_group&i, 2, =);
	%end;
	1
%mend total_groups_definition_is_valid;