/*
*****************************************************************************************************************
Project		 : StatProg
SAS file name: count_categorical.sas
File location: /statprog/macro/count_categorical.sas
*****************************************************************************************************************
Purpose: Macro used to obtain categorical counts/frequencies
Author: Mazi Ntintelo
Creation Date: 2025-03-18
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro count_categorical(data_in=
						,data_out=
						,label=
						,usubjid=usubjid
				    	,subgroup_vars_in=
						,subgroupPreloadfmt=
						,by_vars_in=
						,treatment_var_in=
						,treatment_preloadfmt=
						,define_total_groups=
						,cat_var_in=
						,cat_preloadfmt=
						,section=1
						,indent=0
						,var_out=N
						,subset=); 
	%local
	    i
		random
		macro_name
	    total_groups_size
		subgroup_vars_size
		subgroup_formats_size
		subgroup_char_var_size
		by_vars_size;
		
	/****************************************/
	/**************Validation****************/
	/****************************************/
	
	%let macro_name = &sysmacroname;
	%if %required_parameter_is_null(parameter=section) %then %return;						
	%if %required_parameter_is_null(parameter=data_in) %then %return;
	%if %required_parameter_is_null(parameter=usubjid) %then %return;
	%if %required_parameter_is_null(parameter=label) %then %return;
	%if %required_parameter_is_null(parameter=treatment_var_in) %then %return; 
	%if %required_parameter_is_null(parameter=treatment_preloadfmt) %then %return;
	%if %required_parameter_is_null(parameter=data_out) %then %return; 
	%if %required_parameter_is_null(parameter=cat_var_in) %then %return; 
	%if %required_parameter_is_null(parameter=cat_preloadfmt) %then %return; 
	%if %required_parameter_is_null(parameter=var_out) %then %return; 
	%if %required_parameter_is_null(parameter=indent) %then %return; 
	%if ^%variable_name_is_valid(var_in=&var_out) %then %return;
	%if ^%library_exists(library=gml) %then %return;
	%if ^%dataset_exists(dataset=&data_in) %then %return;
	%if ^%dataset_name_is_valid(datasetName=&data_out) %then %return;	
	%if ^%variable_exists(data_in=&data_in,var_in=&usubjid) %then %return;
	%if ^%variable_exists(data_in=&data_in,var_in=&cat_var_in) %then %return;	
	%if ^%variable_exists(data_in=&data_in,var_in=&treatment_var_in) %then %return;
	%if ^%variable_is_numeric(data_in=&data_in,var_in=&treatment_var_in) %then %return;
	%if ^%integer_value_received(parameter=indent) %then %return;

	%if %substr(&treatment_preloadfmt, 1, 1) = $ %then %let treatment_preloadfmt=%substr(&treatment_preloadfmt, 2); 
	%if %substr(&treatment_preloadfmt, %length(&treatment_preloadfmt)) ne . %then %let treatment_preloadfmt=&treatment_preloadfmt..;
	%if ^%catalog_entry_exists(entry=work.formats.&treatment_preloadfmt.format) %then %return;	

	%if %substr(&cat_preloadfmt, 1, 1) = $ %then %let cat_preloadfmt=%substr(&cat_preloadfmt, 2); 
	%if %substr(&cat_preloadfmt, %length(&cat_preloadfmt)) ne . %then %let cat_preloadfmt=&cat_preloadfmt..;
	%if %variable_type(data_in=&data_in,var_in=&cat_var_in) = C %then %do;
		%if ^%catalog_entry_exists(entry=work.formats.&cat_preloadfmt.formatc) %then %return;
		%let cat_preloadfmt=$&cat_preloadfmt; 
	%end;
	%else %if ^%catalog_entry_exists(entry=work.formats.&cat_preloadfmt.format) %then %return;

	%let label = %sysfunc(dequote(&label)); 
	
	%let subgroup_vars_size=%argument_list_size(argument_list=&subgroup_vars_in);
	%let subgroup_formats_size=%argument_list_size(argument_list=&subgroupPreloadfmt);
	%let total_groups_size=%argument_list_size(argument_list=&define_total_groups);
	%let by_vars_size=%argument_list_size(argument_list=&by_vars_in);

	%do i=1 %to &subgroup_vars_size;
		%local subgroup_var&i
		       subgroup_format&i;
	%end;
	%do i=1 %to &by_vars_size;
		%local by_var&i;
	%end;
	%do i=1 %to &total_groups_size;
		%local totalGroup&i
			   totalGroup&i.condition
			   totalGroup&i.value;            
	%end;
	
	%if ^%total_groups_are_valid %then %return;
	%if ^%subgroups_are_valid %then %return;
	%if ^%by_vars_are_valid %then %return;

	%let subgroup_char_vars_size=%char_subgroups_size;
	%do i=1 %to &subgroup_char_vars_size;
		%local subgroup_char_var&i;            
	%end;

	%char_subgroups_array

	%let random=V%sysfunc(rand(integer, 1, 5E6), hex8.);

	proc sort data=&data_in;
		by &usubjid %subgroups %by_vars &cat_var_in;
	run;

	data gml.prep;
		length &random %char_subgroups
		%if %variable_type(data_in=&data_in,var_in=&cat_var_in) = C %then &cat_var_in;
		$200;
		set &data_in;
		%subset;
		by &usubjid %subgroups %by_vars &cat_var_in;
		if first.&cat_var_in then do;
			output;
			%total_groups
		end;
		call missing(&random);
		keep &usubjid %subgroups %by_vars &cat_var_in &treatment_var_in;
	run;
	
	%if ^%syserr_is_acceptable %then %return;

	%if &by_vars_size %then %do;
		proc sort data=gml.prep;
			by %by_vars;
		run;
	%end;

	proc summary data=gml.prep nway missing completetypes noprint;
		%if &by_vars_size %then %do;
			by %by_vars;
		%end;
		%class_subgroups
		class &treatment_var_in/preloadfmt exclusive;
		class &cat_var_in/preloadfmt exclusive;
		format &treatment_var_in &treatment_preloadfmt
			   &cat_var_in &cat_preloadfmt %format_subgroups;
		output out=gml.cat1;
	run;

	 %let cat_preloadfmt = %trim(%qupcase(%qsysfunc(compress(&cat_preloadfmt, $.))));
	
	proc format cntlout=gml.fmt(where=(fmtname="&cat_preloadfmt" and type = "%variable_type(data_in=&data_in,var_in=&cat_var_in)"));
	run;

	%do i=1 %to %number_of_observations(data_in=gml.fmt);
		%local order&i;
	%end;

	proc sql;
		select 
			%if %variable_type(data_in=&data_in,var_in=&cat_var_in) = C %then %do;
				quote(
			%end;
			strip(start)
			%if %variable_type(data_in=&data_in,var_in=&cat_var_in) = C %then %do;
				)
			%end;
			into: order1-
		from gml.fmt;
	quit;
			
	data &data_out;
		set gml.cat1;
		length label col1 $200;
		label = "&label";
		col1 = vvalue(&cat_var_in);
		array &random [&sqlObs] 
		%if %variable_type(data_in=&data_in,var_in=&cat_var_in) = C %then %do;
			$200
		%end;
		_temporary_ 
		(  %do i=1 %to &sqlObs;
				&&order&i	
			%end;
		);
		_section_ = &section;
		_indent_  = &indent;
		if _indent_ then col1 = repeat(' ', _indent_- 1)!!col1;
		_order1_=which%variable_type(data_in=&data_in,var_in=&cat_var_in)(&cat_var_in, of &random[*]);
		rename _freq_ = &var_out;
		keep &treatment_var_in &cat_var_in %subgroups %by_vars _freq_ col1 _section_ label _order1_ _indent_;
	run;
%mend count_categorical;
