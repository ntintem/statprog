/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: re_join_supplemental_qualifiers.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to re join supplemental qualifiers to parent dataset.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro re_join_supplemental_qualifiers(data_in=
									  ,data_out=
									  ,supp_data_in=);
									  
	%if %sysfunc(%superq(data_in)=, boolean)  or 
		%sysfunc(%superq(data_out)=, boolean) or
		%sysfunc(%superq(supp_data_in)=, boolean)  %then %do;
		%put ERROR: Parameters data_in, data_out and supp_data_in are required;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%sysfunc(exist(%bquote(&data_in))) %then %do;
		%put ERROR: Data &data_in does not exist;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%sysfunc(exist(%bquote(&supp_data_in))) %then %do;
		%put ERROR: Data &supp_data_in does not exist;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%let dsid=%sysfunc(open(&supp_data_in));
	%if ^%sysfunc(varnum(&dsid, idvar)) %then %do;
		%put ERROR: Data &supp_data_in does not exist;
		%put ERROR: Macro &sysmacroname aborted;
		%let rc=%sysfunc(close(&dsid));
		%return;
	%end;
	%if ^%sysfunc(varnum(&dsid, studyid)) %then %do;
		%put ERROR: Data &supp_data_in does not exist;
		%put ERROR: Macro &sysmacroname aborted;
		%let rc=%sysfunc(close(&dsid));
		%return;
	%end;
	%if ^%sysfunc(varnum(&dsid, usubjid)) %then %do;
		%put ERROR: Data &supp_data_in does not exist;
		%put ERROR: Macro &sysmacroname aborted;
		%let rc=%sysfunc(close(&dsid));
		%return;
	%end;
	%let rc=%sysfunc(close(&dsid));
	%local total_idvars;
	proc sql;
		select count(distinct idvar) into: total_idvars from &supp_data_in;
		select distinct idvar into: idvar1- from &supp_data_in;
	quit;
	%let dsid=%sysfunc(open(&supp_data_in));
	%do i=1 %to &total_idvars;
		%if ^%sysfunc(varnum(&dsid, &&idvar&i)) %then %do;
			%put ERROR: Data &supp_data_in does not exist;
			%put ERROR: Macro &sysmacroname aborted;
			%let rc=%sysfunc(close(&dsid));
		%end;
		%local var_type_&i;
		%let var_type_&i = %sysfunc(%sysfunc(vartype(&dsid, varnum(&dsid, &&idvar&i))));
	%end;
	%let rc=%sysfunc(close(&dsid));
	proc sort data=&supp_data_in out=supp_sorted;
		by studyid usubjid idvar idvarval;
	run;
	proc transpose data=supp_sorted out=t_supp;
		by studyid usubjid idvar idvarval;
		var qval;
		id qnam;
		idlabel qlabel;
	run;
	%do i=1 %to &total_idvars;
		
		
	%end;
%mend re_join_supplemental_qualifiers;