/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: trim_char_vars_to_max_length.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to trim all char variables in a dataset to max length.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/


%macro trim_char_vars_to_max_length(data_in=);
	%if %sysevalf(%superq(data_in)=, boolean) %then %do;
		%put ERROR: Parameter data_in is required;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%sysfunc(exist(%bquote(&data_in))) %then %do;
		%put ERROR: Data &data_in does not exist;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%local size
		   dsid
		   i
		   rc;   
	%let dsid=%sysfunc(open(&data_in));
	%let nvar=%sysfunc(attrn(&dsid, nvar));
	%let size=0;
	%if ^&nvar %then %do;
		%put ERROR: No variables found in data &data_in;
		%put ERROR: Macro &sysmacroname aborted;
		%let rc=%sysfunc(close(&dsid));
		%return;
	%end;
	%do i=1 %to &nvar;
		%if %sysfunc(vartype(&dsid, &i)) = C %then %do;
			%let size=%eval(&size + 1);
			%local charvar&size;
			%let charvar&size=%sysfunc(varname(&dsid, &i)); 
		%end;
	%end;
	%let rc=%sysfunc(close(&dsid));
	%if ^&size %then %do;
		%put NOTE: No character variables in data &data_in;
		%put NOTE: No Trimming Done;
		%return;
	%end;
	%do i=1 %to &size;
		%local maxlen&i;
	%end;
	proc sql noprint;
		select coalesce(max(length(&charvar1)), 1)
			%do i=2 %to &size;
			  ,coalesce(max(length(&&charvar&i)), 1)
			 %end;
		into :maxlen1 trimmed
		%do i=2 %to &size;
			,: maxlen&i trimmed
		%end;
		from &data_in;
	quit;
	%do i=1 %to &size;
		%put NOTE: Trimming &&charvar&i to length &&maxlen&i;
	%end;
	proc sql;
		alter table &data_in
			modify &charvar1 char(&maxlen1)
			%do i=2 %to &size;
				,&&charvar&i char(&&maxlen&i)
			%end;
		;
	quit;
%mend trim_char_vars_to_max_length;