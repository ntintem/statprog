/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: sorted_by.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to return the sorted order of a dataset.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro sorted_by(data_in=
				,split_char=);
	%local dsid sorted_by rc;
	%if %sysfunc(%superq(data_in)=, boolean)  %then %do;
		%put ERROR: Parameters data_in is required;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%sysfunc(exist(%bquote(&data_in))) %then %do;
		%put ERROR: Data &data_in does not exist;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%let dsid=%sysfunc(open(&data_in));
	%let sorted_by=%sysfunc(attrc(&dsid, SORTEDBY));
	%let rc=%sysfunc(close(&dsid));
	&sorted_by
%mend sorted_by;