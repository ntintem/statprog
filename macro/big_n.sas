/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: big_n.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get population counts from a dataset. Typically ADSL.
Author: Mazi Ntintelo
Creation Date: 2025-01-23
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro big_n(data_in=
			 ,subset=
			 ,treatment_var_in=
			 ,treatment_preloadfmt=
			 ,define_total_groups=
			 ,usubjid=
			 ,data_out=
			 ,var_out=denom
			 ,subgroup_vars_in=
			 ,subgroup_preloadfmt=
			 ,displayfmt=
			 ,include_big_n=
			 ,big_n_parenthesis=
			 ,split_by=|
			 ,text_below_big_n=
			);
	%local i
		   random
		   type
		   subgroup_vars_size
		   total_groups_size
		   subgroup_formats_size
		   subgroup_char_var_size
		   macro_name;	
 
	%let macro_name = &sysmacroname;

	/****************************************/
	/**************Validation****************/
	/****************************************/
	%if %required_parameter_is_null(parameter=data_in) %then %return;							
	%if %required_parameter_is_null(parameter=data_out) %then %return;
	%if %required_parameter_is_null(parameter=usubjid) %then %return; 
	%if %required_parameter_is_null(parameter=treatment_var_in) %then %return;
	%if %required_parameter_is_null(parameter=treatment_preloadfmt) %then %return;
	%if %required_parameter_is_null(parameter=displayfmt) %then %return;  
	%if %required_parameter_is_null(parameter=include_big_n) %then %return;
	%if %required_parameter_is_null(parameter=big_n_parenthesis) %then %return;
	%if %required_parameter_is_null(parameter=var_out) %then %return;
	%if ^%variable_name_is_valid(var_in=&var_out) %then %return;
	%if ^%library_exists(libref=gml) %then %return;
	%if ^%dataset_exists(data_in=&data_in) %then %return;
	%if ^%dataset_name_is_valid(data_in=&data_out) %then %return;
	%if ^%variable_exists(data_in=&data_in,var_in=&usubjid) %then %return;						
	%if ^%variable_exists(data_in=&data_in,var_in=&treatment_var_in) %then %return;
	%if ^%variable_is_numeric(data_in=&data_in,var_in=&treatment_var_in) %then %return;
	%if ^%yes_no_value_received(parameter=include_big_n) %then %return;
	%if ^%yes_no_value_received(parameter=big_n_parenthesis) %then %return;

	%if &include_big_n=N and (&big_n_parenthesis=Y or %sysevalf(%superq(text_below_big_n)^=, boolean)) %then %do;
		%put WARNING:1/[%sysfunc(datetime(), e8601dt.)] Since include_big_n is N/NO;
		%put WARNING:2/[%sysfunc(datetime(), e8601dt.)] Values Assigned to big_n_parenthesis and text_below_big_n are ignored;
	%end;

	%if %substr(&treatment_preloadfmt, 1, 1) = $ %then %let treatment_preloadfmt=%substr(&treatment_preloadfmt, 2); 
	%if %substr(&treatment_preloadfmt, %length(&treatment_preloadfmt)) ne . %then %let treatment_preloadfmt=&treatment_preloadfmt..;
	%if ^%catalog_entry_exists(entry=work.formats.&treatment_preloadfmt.format) %then %return;								  

	%let subgroup_vars_size=%argument_list_size(argument_list=&subgroup_vars_in);
	%let subgroup_formats_size=%argument_list_size(argument_list=&subgroup_preloadfmt);
	%let total_groups_size=%argument_list_size(argument_list=&define_total_groups);

	%do i=1 %to &subgroup_vars_size;
		%local subgroup_var&i
			   subgroup_format&i;
	%end;
	%do i=1 %to &total_groups_size;
		%local total_group&i
			   total_group&i._condition
			   total_group&i._value;            
	%end;

	%if ^%total_groups_definition_is_valid %then %return;
	%if ^%subgroups_are_valid %then %return;

	%let subgroup_char_vars_size=%char_subgroups_size;
	%do i=1 %to &subgroup_char_vars_size;
		%local subgroup_char_var&i;            
	%end;

	%char_subgroups_array
	
	proc sql;
		create table gml.repeats as 
			select &usubjid
				  ,count(&usubjid) as count
			from &data_in 
			%subset
			group by &usubjid
			having count(&usubjid) > 1;
	quit;
	
	%if ^%syserr_is_acceptable %then %return;

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

	%let random=V%sysfunc(rand(integer, 1, 5E6), hex8.);

	data gml.prep;
		length &random %char_subgroups $200;
		set &data_in;
		%subset;
		call missing(&random);
		output;
		%total_groups
		keep &treatment_var_in %subgroups;
	run;

	/****************************************/
	/***************Get Big N****************/
	/****************************************/
	

	proc summary data=gml.prep completetypes nway;
		class &treatment_var_in/preloadfmt exclusive;
		%class_subgroups
		format &treatment_var_in &treatment_preloadfmt
			   %format_subgroups;
		output out=gml.bign1;
	run;

	%if %qsubstr(&displayfmt, %length(&displayfmt)) ne . %then %let displayfmt=&displayfmt..;
	
	data &data_out;
		set gml.bign1;
		length label countc displayfmt gmacrovar $200;
		
		%if &big_n_parenthesis=Y %then %do;
			countc = cats('(N=', _freq_, ')');
		%end;
		%else %do;
			countc = cats('N=', _freq_);
		%end;

		displayfmt = put(&treatment_var_in, &displayfmt -l);

		%if &include_big_n=Y %then %do;
			label=catx("&split_by", displayfmt, countc, "&text_below_big_n");
		%end;
		%else %do;
			label=catx("&split_by", displayfmt);
		%end;

		gmacrovar = cats('_', catx('_', of %subgroups &treatment_var_in));
		call symputx(gmacrovar, label, 'g');
		rename _freq_ = &var_out;
		keep _freq_ &treatment_var_in %subgroups label gmacrovar;
	run;
	
%mend big_n;