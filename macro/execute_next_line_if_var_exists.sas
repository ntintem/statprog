/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: execute_next_line_if_var_exists.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to conditionally execute following line within a datastep.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/


%macro execute_next_line_if_var_exists(data_in=
									  ,var_in=);
	%local rc dsid val;							  
	%if %sysevalf(%superq(data_in)=, boolean) or
		%sysevalf(%superq(var_in)=, boolean) %then %do;
		%put ERROR: Parameter data_in and var_in is required;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%sysfunc(exist(%bquote(&data_in))) %then %do;
		%put ERROR: Data &data_in does not exist;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%sysfunc(prxmatch(%str(m/^[A-Za-z_][A-Za-z_0-9]{1,31}$/oi), %bquote(&var_in))) %then %do;
		%put ERROR: %bquote(&var_in) does not refer to valid SAS variable Name;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%let val=;
	%let dsid=%sysfunc(open(&data_in));
	%if ^%sysfunc(varnum(&dsid, &var_in)) %then %let val=%str(*);
	%let rc=%sysfunc(close(&dsid));	
	&val
%mend execute_next_line_if_var_exists;