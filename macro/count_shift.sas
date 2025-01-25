/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: count_shift.sas
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


%macro count_shift(data_in=
				        ,data_out=
				        ,treatment_var_in=
				        ,treatment_preloadfmt=
				        ,define_total_groups=
				        ,subgroup_vars_in=
				        ,subgroup_preloadfmt=
				        ,by_vars_in=
				        ,usubjid=usubjid
				        ,subset=
				        ,var_out=denom
				        ,section=1
				        ,base_var_in=
				        ,base_preloadfmt=
				        ,post_base_var_in=
				        ,post_base_preloadfmt=);

	%local i
		   type
		   subgroup_vars_size
		   total_groups_size
		   by_vars_size
		   subgroup_formats_size
		   subgroup_char_vars_size
		   base_var_type
		   post_base_var_type
		   random
		   macro_name;	
 
	%let macro_name = &sysmacroname;

	/****************************************/
	/**************Validation****************/
	/****************************************/

	%if %required_parameter_is_null(parameter=data_in) %then %return;							
	%if %required_parameter_is_null(parameter=data_out) %then %return;
	%if %required_parameter_is_null(parameter=usubjid) %then %return;
	%if %required_parameter_is_null(parameter=section) %then %return;	 
	%if %required_parameter_is_null(parameter=treatment_var_in) %then %return;
	%if %required_parameter_is_null(parameter=treatment_preloadfmt) %then %return;
	%if %required_parameter_is_null(parameter=base_var_in) %then %return;  
	%if %required_parameter_is_null(parameter=post_base_var_in) %then %return;  
	%if %required_parameter_is_null(parameter=base_preloadfmt) %then %return;  
	%if %required_parameter_is_null(parameter=post_base_preloadfmt) %then %return;  
	%if %required_parameter_is_null(parameter=var_out) %then %return;
	%if ^%library_exists(library=gml) %then %return;
	%if ^%dataset_exists(data_in=&data_in) %then %return;
	%if ^%dataset_name_is_valid(data_in=&data_out) %then %return;
	%if ^%variable_exists(data_in=&data_in,var_in=&usubjid) %then %return;						
	%if ^%variable_exists(data_in=&data_in,var_in=&treatment_var_in) %then %return;
	%if ^%variable_is_numeric(data_in=&data_in,var_in=&treatment_var_in) %then %return;
	%if ^%variable_exists(data_in=&data_in,var_in=&base_var_in) %then %return;
	%if ^%variable_exists(data_in=&data_in,var_in=&post_base_var_in) %then %return;

	%if %substr(&treatment_preloadfmt, 1, 1) = $ %then %let treatment_preloadfmt=%substr(&treatment_preloadfmt, 2); 
	%if %substr(&treatment_preloadfmt, %length(&treatment_preloadfmt)) ne . %then %let treatment_preloadfmt=&treatment_preloadfmt..;
	%if ^%catalog_entry_exists(entry=work.formats.&treatment_preloadfmt.format) %then %return;

	%let base_var_type = %variable_type(data_in=&data_in, var_in=&base_var_in);
	%if %substr(&base_preloadfmt, 1, 1) = $ %then %let base_preloadfmt=%substr(&base_preloadfmt, 2); 
	%if %substr(&base_preloadfmt, %length(&base_preloadfmt)) ne . %then %let base_preloadfmt=&base_preloadfmt..;
	%if ^%catalog_entry_exists(entry=work.formats.&base_preloadfmt.format%sysfunc(ifc(&base_var_type=C, C, %str( )))) %then %return;
	%if &base_var_type=C %then %let base_preloadfmt=$&base_preloadfmt;


	%let post_base_var_type = %variable_type(data_in=&data_in, var_in=&post_base_var_in);
	%if %substr(&post_base_preloadfmt, 1, 1) = $ %then %let post_base_preloadfmt=%substr(&post_base_preloadfmt, 2); 
	%if %substr(&post_base_preloadfmt, %length(&post_base_preloadfmt)) ne . %then %let post_base_preloadfmt=&post_base_preloadfmt..;
	%if ^%catalog_entry_exists(entry=work.formats.&post_base_preloadfmt.format%sysfunc(ifc(&post_base_var_type=C, C, %str( )))) %then %return;
	%if &post_base_var_type=C %then %let post_base_preloadfmt=$&post_base_preloadfmt;
	

	%let subgroup_vars_size=%argument_list_size(argument_list=&subgroup_vars_in);
	%let subgroup_formats_size=%argument_list_size(argument_list=&subgroup_preloadfmt);
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
		%local total_group&i
			   total_group&i._condition
			   total_group&i._value;            
	%end;

	%if ^%total_groups_are_valid %then %return;
	%if ^%subgroups_are_valid %then %return;
	%if ^%by_vars_are_valid %then %return;

	%let subgroup_char_vars_size=%char_subgroups_size;
	%do i=1 %to &subgroup_char_vars_size;
		%local subgroup_char_var&i;            
	%end;

	%char_subgroups_array
	
	proc sql;
		create table gml.repeats as 
			select &usubjid
				  ,count(&usubjid) as count
				   %do i=1 %to &by_vars_size;
			         	,&&by_var&i
			       %end;
			       %do i=1 %to &&subgroup_vars_size;
			         	,&&subgroup_var&i
			       %end;
			from &data_in 
			%subset
			group by &usubjid
			         %do i=1 %to &by_vars_size;
			         	,&&by_var&i
			         %end;
			          %do i=1 %to &&subgroup_vars_size;
			         	,&&subgroup_var&i
			         %end;
			having count(&usubjid) > 1;
	quit;

	%if %number_of_observations(data_in=gml.repeats) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Key combination of variable/s &usubjid does not yield a unique row;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Please Ensure that key combination yields a unique row;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] See gml.repeats data for further details;
		%put ERROR:4/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;

	/****************************************/
	/**************Prep Data*****************/
	/****************************************/

	%let random = V%sysfunc(rand(integer, 1, 5E6), hex8.);

	data gml.shift01;
		length &random %char_subgroups 
		%if &base_var_type=C %then %do;
			&base_var_in
		%end; 
		%if &post_base_var_type=C %then %do;
			&post_base_var_in
		%end; 
		$200;
		set &data_in;
		%subset;
		call missing(&random);
		output;
		%total_groups
		keep &treatment_var_in %subgroups %by_vars &post_base_var_in &base_var_in &usubjid;
	run;

	%if &by_vars_size %then %do;
		proc sort data=gml.shift01;
			by %by_vars;
		run;
	%end;

	proc summary data=gml.shift01 missing completetypes nway;
		%if &by_vars_size %then %do;
			by %by_vars;
		%end;
		class &treatment_var_in/preloadfmt exclusive;
		class &post_base_var_in &base_var_in/ mlf preloadfmt exclusive;
		%class_subgroups
		format &treatment_var_in &treatment_preloadfmt &post_base_var_in &post_base_preloadfmt &base_var_in &base_preloadfmt
			   %format_subgroups;
		output out=gml.shift02;
	run;

	data &data_out;
		set gml.shift02;
		length col1 postbase $200;
		_section_=&section;
		col1 = vvalue(&base_var_in);
		postbase=vvalue(&post_base_var_in);
		rename _freq_ = &var_out;
	run;
%mend count_shift;