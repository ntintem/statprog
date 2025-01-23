/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: count_one_row.sas
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

%macro count_one_row(data_in=
					,data_out=one_row
					,label=
					,usubjid=usubjid
				    ,subgroup_vars_in=
					,subgroup_preloadfmt=
					,by_vars_in=
					,treatment_var_in=
					,treatment_preloadfmt=
					,define_total_groups=
					,subset=
					,section=1
					,order1=1
					,event_count_var_out=
					,subject_count_var_out=
					,indent=0
				   ) /minoperator;
	%local
	    i
		macro_name
	    total_groups_size
		subgroup_vars_size
		subgroup_formats_size
		subgroup_char_vars_size
		by_vars_size;	
	
	/****************************************/
	/**************Validation****************/
	/****************************************/
	%let macro_name = &sysmacroname;
	%if %required_parameter_is_null(parameter=section) %then %return;	
	%if %required_parameter_is_null(parameter=order1) %then %return;			
	%if %required_parameter_is_null(parameter=data_in) %then %return;
	%if %required_parameter_is_null(parameter=data_out) %then %return;
	%if %required_parameter_is_null(parameter=usubjid) %then %return;
	%if %required_parameter_is_null(parameter=treatment_var_in) %then %return; 
	%if %required_parameter_is_null(parameter=treatment_preloadfmt) %then %return; 
	%if %required_parameter_is_null(parameter=label) %then %return;
	%if %required_parameter_is_null(parameter=indent) %then %return; 
	%if ^%library_exists(libref=gml) %then %return;
	%if ^%dataset_exists(data_in=&data_in) %then %return;
	%if ^%dataset_name_is_valid(data_in=&data_out) %then %return;	
	%if ^%variable_exists(data_in=&data_in,varIn=&usubjid) %then %return;							
	%if ^%variable_exists(data_in=&data_in,varIn=&treatment_var_in) %then %return;
	%if ^%variable_is_numeric(data_in=&data_in,varIn=&treatment_var_in) %then %return;
	%if ^%integer_value_received(parameter=indent) %then %return;

	%if %sysevalf(%superq(event_count_var_out)=, boolean) and %sysevalf(%superq(subject_count_var_out)=, boolean) %then %do;
		%put NOTE:1/[%sysfunc(datetime(), e8601dt.)] Both event_count_var_out and subject_count_var_out Parameters are null;
		%put NOTE:2/[%sysfunc(datetime(), e8601dt.)] Resetting to defaults;
		%put NOTE:3/[%sysfunc(datetime(), e8601dt.)] Assing variable name to event_count_var_out or subject_count_var_out if only one is desired;
		%let event_count_var_out = NEVT;
		%let subject_count_var_out = NSUB;
	%end;
	%if %qupcase(&event_count_var_out) = %qupcase(&subject_count_var_out) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] event_count_var_out and subject_count_var_out cannot be the same as they become variable names;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;

	%if %substr(&treatment_preloadfmt, 1, 1) = $ %then %let treatment_preloadfmt=%substr(&treatment_preloadfmt, 2); 
	%if %substr(&treatment_preloadfmt, %length(&treatment_preloadfmt)) ne . %then %let treatment_preloadfmt=&treatment_preloadfmt..;
	%if catalog_entry_exists(entry=work.formats.&treatment_preloadfmt.format) %then %return;

	%let label = %sysfunc(dequote(&label));  

	%let subgroup_vars_size=%argument_list_size(argument_list=&subgroup_vars_in);
	%let subgroup_formats_size=%argument_list_size(argument_list=&subgroup_preloadfmt);
	%let total_groups_size=%argument_list_size(argument_list=&define_total_groups);
	%let by_vars_size=%argument_list_size(argument_list=&by_vars_in);
	
	%do i=1 %to &subgroup_vars_size;
		%local subgroup_var&i
			   subgroup_format&i;
	%end;
	%do i=1 %to &total_groups_size;
		%local total_group&i
			   total_group&i._condition
			   total_group&i._value;            
	%end;
	%do i=1 %to &by_vars_size;
		%local by_var&i;
	%end;

	%if ^%total_groups_are_valid %then %return;
	%if ^%subgroups_are_valid %then %return;
	%if ^%by_vars_are_valid %then %return;

	%let subgroup_char_vars_size=%char_subgroups_size;
	%do i=1 %to &subgroup_char_vars_size;
		%local subgroup_char_var&i;            
	%end;

	%char_subgroups_array
	
	proc sort data=&data_in;
		by &usubjid %subgroups %by_vars;
	run;

	data gml.prep;
		length id_var col1 %char_subgroups $200;
		set &data_in;
		%subset
		by &usubjid %subgroups %by_vars;
		col1="&label";
		%if %sysevalf(%superq(event_count_var_out)^=, boolean) %then %do;
			id_var = "&event_count_var_out";
			output;
			%total_groups
		%end;
		%if %sysevalf(%superq(subject_count_var_out)^=, boolean) %then %do;
			if first.%if &by_vars_size %then &&by_var&by_vars_size;
					 %else &usubjid; then do;
				id_var = "&subject_count_var_out";
				output;
				%total_groups
			end;
		%end;
		keep &treatment_var_in id_var col1 %subgroups %by_vars;
	run;
	
	%if ^%syserr_is_acceptable %then %return;

	proc sort data=gml.prep;
		by col1 id_var %by_vars;
	run;
	
	proc summary data=gml.prep missing completetypes nway;
		by col1 id_var %by_vars;
		class &treatment_var_in / exclusive preloadfmt;
		%class_subgroups
		format &treatment_var_in &treatment_preloadfmt %format_subgroups;
		output out=gml.countOnerow1;
	run;

	proc sort data=gml.countOnerow1;
		by col1 %subgroups &treatment_var_in %by_vars id_var;
	run;
	
	proc transpose data=gml.countOnerow1 out=gml.countOnerow2;
		by col1 %subgroups &treatment_var_in %by_vars;
		var _freq_;
		id id_var;
	run;
	
	data &data_out;
		set gml.countOnerow2;
		_section_=&section;
		_order1_=&order1;
		_indent_  = &indent;
		if _indent_ then col1 = repeat(' ', _indent_- 1)!!col1;
		keep %subgroups &treatment_var_in %by_vars &event_count_var_out &subject_count_var_out col1 _section_ _order1_ _indent_;
	run;
%mend count_one_row;