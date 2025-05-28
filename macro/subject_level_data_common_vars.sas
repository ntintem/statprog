/*
*****************************************************************************************************************
Project		 : StatProg
SAS file name: subject_level_data_common_vars.sas
File location: /statprog/macro/subject_level_data_common_vars.sas
*****************************************************************************************************************
Purpose: Macro used to obtain common variables from ADSL specification.
Author: Mazi Ntintelo
Creation Date: 2025-05-28
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro subject_level_data_common_vars(spec_lib=
									 ,split_common_vars_by=
								     ,ignore_vars=STUDYID#USUBJID) /minoperator mindelimiter='#';
	%local i
		   dsid
		   rc
		   macro_name
		   common_var
		   common_vars;		   
	%let macro_name = &sysmacroname;	   
	%if %required_parameter_is_null(parameter=spec_lib) %then %return;
	%if %length(%bquote(&split_common_vars_by))> 1 %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] %bquote(&split_common_vars_by) is too long.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Only specify a single character;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%sysevalf(%superq(ignore_vars)=, boolean) and ^%sysfunc(prxmatch(%str(m/^\w+(#\w+)*$/oi), %bquote(&ignore_vars))) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Invalid pattern specified for ignore_vars parameter;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Each variable to exclude should be separated by a hash tag #. Otherwise ignore_vars should be left null;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%library_exists(libref=&spec_lib) %then %return;
	%if ^%dataset_exists(data_in=&spec_lib..adsl) %then %return;
	%if ^%variable_exists(data_in=&spec_lib..adsl,var_in=variable__name) %then %return;						
	%if ^%variable_exists(data_in=&spec_lib..adsl,var_in=adsl__core) %then %return;
	%if ^%variable_exists(data_in=&spec_lib..adsl,var_in=include_y_n_) %then %return;
	%if ^%eval(%variable_type(data_in=&spec_lib..adsl,var_in=adsl__core)     = C and
		       %variable_type(data_in=&spec_lib..adsl,var_in=variable__name) = C and 
			   %variable_type(data_in=&spec_lib..adsl,var_in=include_y_n_)   = C) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Variables ADSL__CORE/VARIABLE__NAME/INCLUDE_Y_N_ in &spec_lib..adsl data are not in expected type;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Expected type is Character;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &sysmacroname aborted;
		%return;	
	%end;
	%let common_vars=;
	%if %bquote(&split_common_vars_by)= %then %let split_common_vars_by=%str( );
	%let dsid=%sysfunc(open(&spec_lib..adsl));
	%do %while(^%sysfunc(fetch(&dsid)));
		%if %sysfunc(getvarc(&dsid, %sysfunc(varnum(&dsid, adsl__core))))   = Y and
			%sysfunc(getvarc(&dsid, %sysfunc(varnum(&dsid, include_y_n_)))) = Y %then %do;
			%let common_var=%qupcase(%sysfunc(getvarc(&dsid, %sysfunc(varnum(&dsid, variable__name)))));
			%if ^%eval(%bquote(&common_var) in %qupcase(&ignore_vars)) %then %do;
				%if %length(&common_vars) > 0 %then %let common_vars=&common_vars%bquote(&split_common_vars_by)&common_var;
				%else %let common_vars=&common_var;
			%end;
		%end;
	%end;
	%let rc=%sysfunc(close(&dsid));
	&commonVars
%mend subject_level_data_common_vars;