/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: counts_nested.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get nested counts. Typically used for safety analysis.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro count_nested(data_in=
				   ,data_out=nested_count
				   ,usubjid=usubjid
				   ,subgroup_vars_in=
				   ,subgroup_preloadfmt=
				   ,by_vars_in=
				   ,treatment_var_in=
				   ,treatment_preloadfmt=
				   ,define_total_groups=
				   ,nested_vars_in=
				   ,nested_vars_indent=
				   ,cat_var_in=
				   ,cat_preloadfmt=
				   ,subset=
				   ,section=2
				   ,event_count_var_out=
				   ,subject_count_var_out=
				);
	%local
	    i
		random
		macro_name
	    total_groups_size
		subgroup_vars_size
		subgroup_formats_size
		subgroup_char_vars_size
		by_vars_size
		nested_vars_size
		nested_vars_indent_size;	
		
	/****************************************/
	/**************Validation****************/
	/****************************************/

	%let macro_name = &sysmacroname;
	%if %required_parameter_is_null(parameter=section) %then %return;						
	%if %required_parameter_is_null(parameter=data_in) %then %return;
	%if %required_parameter_is_null(parameter=usubjid) %then %return;
	%if %required_parameter_is_null(parameter=treatment_var_in) %then %return; 
	%if %required_parameter_is_null(parameter=treatment_preloadfmt) %then %return;
	%if %required_parameter_is_null(parameter=data_out) %then %return; 
	%if %required_parameter_is_null(parameter=nested_vars_in) %then %return;
	%if %required_parameter_is_null(parameter=nested_vars_indent) %then %return;
	%if ^%library_exists(libref=gml) %then %return;
	%if ^%dataset_exists(data_in=&data_in) %then %return;
	%if ^%dataset_name_is_valid(data_in=&data_out) %then %return;	
	%if ^%variable_exists(data_in=&data_in,var_in=&usubjid) %then %return;							
	%if ^%variable_exists(data_in=&data_in,var_in=&treatment_var_in) %then %return;
	%if ^%variable_is_numeric(data_in=&data_in,var_in=&treatment_var_in) %then %return;

	%if %sysevalf(%superq(event_count_var_out)=, boolean) and %sysevalf(%superq(subject_count_var_out)=, boolean) %then %do;
		%put WARNING:1/[%sysfunc(datetime(), e8601dt.)] Both event_count_var_out and SubjectCount Parameters are null;
		%put WARNING:2/[%sysfunc(datetime(), e8601dt.)] Resetting to defaults;
		%put WARNING:3/[%sysfunc(datetime(), e8601dt.)] Assign a variable name to event_count_var_out or subject_count_var_out if only one is desired;
		%let event_count_var_out = NEVT;
		%let subject_count_var_out = NSUB;
	%end;
	%if %qupcase(&event_count_var_out) = %qupcase(&subject_count_var_out) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] event_count_var_out and SubjectCount cannot be the same as they become variable names;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;
	%if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
		%if %required_parameter_is_null(parameter=cat_preloadfmt) %then %return; 
		%if ^%variable_exists(data_in=&data_in,var_in=&cat_var_in) %then %return;					
		%if ^%variable_is_numeric(data_in=&data_in,var_in=&treatment_var_in) %then %return;
		%if %substr(&cat_preloadfmt, 1, 1) = $ %then %let cat_preloadfmt=%substr(&cat_preloadfmt, 2); 
		%if %substr(&cat_preloadfmt, %length(&cat_preloadfmt)) ne . %then %let cat_preloadfmt=&treatment_preloadfmt..;
		%if ^%catalog_entry_exists(entry=work.formats.&cat_preloadfmt.format) %then %return;					
	%end;

	%if %substr(&treatment_preloadfmt, 1, 1) = $ %then %let treatment_preloadfmt=%substr(&treatment_preloadfmt, 2); 
	%if %substr(&treatment_preloadfmt, %length(&treatment_preloadfmt)) ne . %then %let treatment_preloadfmt=&treatment_preloadfmt..;
	%if ^%catalog_entry_exists(entry=work.formats.&treatment_preloadfmt.format) %then %return;								  

	%let subgroup_vars_size=%argument_list_size(argument_list=&subgroup_vars_in);
	%let subgroup_formats_size=%argument_list_size(argument_list=&subgroup_preloadfmt);
	%let total_groups_size=%argument_list_size(argument_list=&define_total_groups);
	%let by_vars_size=%argument_list_size(argument_list=&by_vars_in);
	%let nested_vars_size=%argument_list_size(argument_list=&nested_vars_in);
	%let nested_vars_indent_size=%argument_list_size(argument_list=&nested_vars_indent);

	%if &nested_vars_size ne &nested_vars_indent_size %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Unbalanced number of nested vars and nested var indends;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Number of nested var indents must mach number of nested variables;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;
	%do i=1 %to &nested_vars_indent_size;
		%local nested_var_indent&i;
		%let nested_var_indent&i=%scan(&nested_vars_indent, &i, #);
		%if ^%integer_value_received(parameter=nested_var_indent&i) %then %return;
	%end;		
	%do i=1 %to &nested_vars_size;
		%local nested_var&i;
		%let nested_var&i=%scan(&nested_vars_in, &i, #);
		%if ^%variable_exists(data_in=&data_in, var_in=&&nested_var&i) %then %return;
	%end;
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
		by &usubjid %subgroups %by_vars
			%do i=1 %to &nested_vars_size;
				&&nested_var&i
			%end;;
	run;

	%let random=V%sysfunc(rand(integer, 1, 5E6), hex8.);

	data gml.prep(rename=(
							%do i=1 %to &nested_vars_size;
								&random._level_&i = &&nested_var&i
							%end;
							%if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
								&random.max = &cat_var_in
							%end;
							));
		length %char_subgroups &random.id_var col1 &random._level_1 - &random._level_&nested_vars_size $200;
		set &data_in;
		%subset;
		by &usubjid %subgroups %by_vars 
		%do i=1 %to &nested_vars_size;
			&&nested_var&i
		%end;;
		%if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
			retain &random._max_level_1 - &random._max_level_&nested_vars_size;
		%end;
		%do i=1 %to &nested_vars_size;
			%if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
				if first.&&nested_var&i then &random._max_level_&i=-&sysMaxLong.;
				&random._max_level_&i = max(&random._max_level_&i, &cat_var_in);
			%end;
			_indent_ = &&nested_var_indent&i;
			nested_var_level=&i;
			col1=cats(&&nested_var&i);
			&random._level_&i=&&nested_var&i;
			%if %sysevalf(%superq(event_count_var_out)^=, boolean) %then %do;
				&random.id_var = symget('event_count_var_out');
				%if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
					&random.max = &cat_var_in;
				%end;
				output;
				%total_groups
			%end;
			%if %sysevalf(%superq(subject_count_var_out)^=, boolean) %then %do;
				if last.&&nested_var&i then do;
			    	&random.id_var = symget('subject_count_var_out');
					%if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
						&random.max = &random._max_level_&i;
					%end;
					output;
					%total_groups
				end;
			%end;
		%end;
		keep col1 
			&treatment_var_in 
			&random.id_var 
			nested_var_level 
			%subgroups 
			%by_vars 
			&random._level_: 
			_indent_
		%if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
			&random.max 
		%end;;
	run;
	
	%if ^%syserr_is_acceptable %then %return;
	
	proc sort data=gml.prep;
		by %subgroups %by_vars
			%do i=1 %to &nested_vars_size;
				&&nested_var&i
		    %end;
		    &cat_var_in;
	run;

	%*********************************************************;
	%**************Create default order variables*************;
	%*********************************************************;

	 data gml.prep02;
	 	set gml.prep;
		by %subgroups %by_vars
		   %do i=1 %to &nested_vars_size;
				&&nested_var&i
		   %end;;
		%if &by_vars_size or &subgroup_vars_size %then %do;
			if first.
			%if &by_vars_size %then &&by_var&by_vars_size;
			%else %if &subgroup_vars_size %then &&subgroup&subgroup_vars_size;
			then do;
				%do i=1 %to &nested_vars_size;
					_order&i._ = 0;
				%end;
			end;
		%end;
		%do i=1 %to %eval(&nested_vars_size - 1);
			if first.&&nested_var&i then _order%eval(&i + 1)_ =0;
		%end;
		%do i=1 %to &nested_vars_size;
			if first.&&nested_var&i then _order&i._ + 1;
		%end;
	run;

	proc sort data=gml.prep02;
		by nested_var_level _indent_ %by_vars 
			%do i=1 %to &nested_vars_size;
				_order&i._
				&&nested_var&i
			%end;
		col1 
		&random.id_var;
	run;
	
	proc summary data=gml.prep02 missing completetypes nway;
		by nested_var_level _indent_ %by_vars 
		   %do i=1 %to &nested_vars_size;
		   		_order&i._
				&&nested_var&i
		   %end;
		col1 
		&random.id_var;
		class &treatment_var_in/exclusive preloadfmt;
		%if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
			class &cat_var_in/exclusive preloadfmt;
		%end;
		%class_subgroups
		format &treatment_var_in &treatment_preloadfmt 
		%if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
			&cat_var_in &cat_preloadfmt
		%end;
		%format_subgroups;
		output out=gml.nested_count1;
	run;

	proc sort data=gml.nested_count1;
		by nested_var_level _indent_ %subgroups %by_vars  
			%do i=1 %to &nested_vars_size;
				_order&i._
				&&nested_var&i
			%end;
			col1
			%if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
				&cat_var_in
			%end;
			&treatment_var_in 
			&random.id_var;
	run;
	
	proc transpose data=gml.nested_count1 out=gml.nested_count2;
		by nested_var_level _indent_ %subgroups %by_vars  
			%do i=1 %to &nested_vars_size;
				_order&i._
				&&nested_var&i
			%end;
			col1 
			%if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
				&cat_var_in
			%end;
			&treatment_var_in;
		var _freq_;
		id &random.id_var;
	run;
	
	data &data_out;
		set gml.nested_count2;
		_section_=&section;
		if _indent_ then col1 = repeat(' ', _indent_ - 1)!!col1;
		keep %subgroups %by_vars col1 _section_ nested_var_level &treatment_var_in &subject_count_var_out &event_count_var_out _indent_
			 %if %sysevalf(%superq(cat_var_in)^=, boolean) %then %do;
				&cat_var_in
			 %end;
			 %do i=1 %to &nested_vars_size;
				_order&i._
			 	&&nested_var&i
			 %end;;
	run;
%mend count_nested;