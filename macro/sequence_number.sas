/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: sequence_number.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to generate sequence number.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/


%macro sequence_number(data_in=
					  ,data_out=
					  ,var_out=
					  ,sort_order=);		  
	%local rc dsid val found_index usubjid_found libref;							  
	%if %sysevalf(%superq(data_in)=, boolean)    or
		%sysevalf(%superq(data_out)=, boolean)     or 
		%sysevalf(%superq(var_out)=, boolean)    or 
		%sysevalf(%superq(sort_order)=, boolean) %then %do;
		%put ERROR: Parameters data_in, data_out, var_out and sort_order are required;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%sysfunc(exist(%bquote(&data_in))) %then %do;
		%put ERROR: Data &data_in does not exist;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%sysfunc(prxmatch(%str(m/^[A-Za-z_][A-Za-z_0-9]{1,31}$/oi), %bquote(&var_out))) %then %do;
		%put ERROR: %bquote(&var_in) does not refer to valid SAS variable Name;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%if %sysfunc(prxmatch(%str(m/^[A-Za-z_][A-Za-z_0-9]{1,7}[.][A-Za-z_][A-Za-z_0-9]{1,31}$/oi), %bquote(&data_out))) %then %do;
		%let libref=%scan(&data_out, 1, .);
		%if %sysfunc(libref(&libref)) %then %do;
	 		%put ERROR: dataOut is a valid SAS 2 level name, however libref &libref is not assigned;
	 		%put ERROR: Macro &sysmacroname aborted;
			%return;
		%end;
	%end;
	%else %if ^%sysfunc(prxmatch(%str(m/^[A-Za-z_][A-Za-z_0-9]{1,31}$/oi), %bquote(&data_out))) %then %do;
	 	%put ERROR: data_out is not a valid SAS dataset name;
		%return;
	%end;
	%if ^%sysfunc(prxmatch(%str(m/^\w+((#\w+))?$/oi), %bquote(&sort_order))) %then %do;
	 	%put ERROR: Invalid selection for sort_order parameter;
	 	%put ERROR: Separate mulitple variables with a hash tag (#);
	 	%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%let dsid=%sysfunc(open(&data_in));
	%if %sysfunc(varnum(&dsid, &var_out)) %then %do;
		%put ERROR: Variable &var_out already exists in &data_in data;
		%put ERROR: Macro &sysmacroname aborted;
		%let rc=%sysfunc(close(&dsid));
		%return;
	%end;
	%let usubjid_found=0;
	%do i=1 %to %sysfunc(countw(&sort_order, #));
		%local sort_var_&i;
		%let sort_var_&i=%scan(&sort_order, &i, #);
		%if %qupcase(&&sort_var_&i) = USUBJID %then %do;
			%let usubjid_found=1;
			%let found_index=&i;
		%end;
		%if ^%sysfunc(varnum(&dsid, &&sort_var_&i)) %then %do;
			%put ERROR: Variable &&sort_var_&i not found in &data_in data;
			%put ERROR: data &data_in cannot be sorted;
			%put ERROR: Macro &sysmacroname aborted;
			%let rc=%sysfunc(close(&dsid));
			%return;
		%end;
	%end;
	%let rc=%sysfunc(close(&dsid));
	%if ^&usubjid_found %then %do;
		%put ERROR: Variable USUBJID not specified in sort_order parameter;
		%put ERROR: Specifying USUBJID in sort_order parameter is required;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	
	proc sort data=&data_in;
		by 
		%do i=1 %to %sysfunc(countw(&sort_order, #));
			&&sort_var_&i
		%end;
		;
	run;
	
	data &data_out;
		set &data_in;
		by 
		%do i=1 %to &found_index;
			&&sort_var_&i
		%end;
		;
		if first.usubjid then &var_out=0;
		&var_out+1;
	run;
%mend sequence_number;