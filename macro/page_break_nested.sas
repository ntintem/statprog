/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: page_break_nested.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating a summary by country and site
Author: Mazi Ntintelo
Creation Date: 2024-09-18
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro page_break_nested(data_in=
				  	    ,data_out=
				        ,subgroup_vars_in=
						,by_vars_in=
						,continued_label=(cont.)
						,nested_vars_in=
						,lines_per_page=20
						,clear_vars_in=
						,cat_var_in=
						);
	%local
	  	random
	    i
		j
		macro_name
		subgroup_vars_size
		by_vars_size
		clear_vars_size
		nested_vars_size;	
		
	/****************************************/
	/**************Validation****************/
	/****************************************/

	%let macro_name = &sysmacroname;
	%if %required_parameter_is_null(parameter=data_in) %then %return;
	%if %required_parameter_is_null(parameter=lines_per_page) %then %return;
	%if %integer_value_received(parameter=lines_per_page) %then %return;	
	%if %required_parameter_is_null(parameter=continued_label) %then %return;
	%if %required_parameter_is_null(parameter=data_out) %then %return; 
	%if %required_parameter_is_null(parameter=nested_vars_in) %then %return;
	%if ^%library_exists(libref=gml) %then %return;
	%if ^%dataset_exists(data_in=&data_in) %then %return;
	%if ^%dataset_name_is_valid(data_in=&data_out) %then %return;	
	%if ^%variable_exists(data_in=&data_in,var_in=col1) %then %return;	
	%if ^%variable_is_character(data_in=&data_in,var_in=col1) %then %return;	
	%if %internal_derived_variable_exists(data_in=&data_in,var_in=page) %then %return;	

	%if &lines_per_page <= 0 %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Invalid value for lines_per_page;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Valid value must be a positive integer greater than 0;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;
	
	%let subgroup_vars_size=%argument_list_size(argument_list=&subgroup_vars_in);
	%let by_vars_size=%argument_list_size(argument_list=&by_vars_in);
	%let nested_vars_size=%argument_list_size(argument_list=&nested_vars_in);
	%let clear_vars_size=%argument_list_size(argument_list=&clear_vars_in);

	%do i=1 %to &nested_vars_size;
		%local nested_var&i;
		%let nested_var&i=%scan(&nested_vars_in, &i, #);
		%if ^%variable_exists(data_in=&data_in, var_in=&&nested_var&i) %then %return;
		%if ^%variable_exists(data_in=&data_in, var_in=_order&i._) %then %return;
		%if ^%variable_is_numeric(data_in=&data_in,var_in=_order&i._) %then %return;	
	%end;
	%do i=1 %to &subgroup_vars_size;
		%local subgroup_var&i;
		%let subgroup_var&i=%scan(&subgroup_vars_in, &i, #);
		%if ^%variable_exists(data_in=&data_in, var_in=&&subgroup_var&i) %then %return;
	%end;
	%do i=1 %to &clear_vars_size;
		%local clear_var&i;
		%let clear_var&i=%scan(&clear_vars_in, &i, #);
		%if ^%variable_exists(data_in=&data_in, var_in=&&clear_var&i) %then %return;
	%end;
	%do i=1 %to &by_vars_size;
		%local by_var&i;
	%end;

	%if %by_vars_are_valid %then %return;

	%if ^%sysevalf(%superq(cat_var_in)=, boolean) %then %do;
		%if ^%variable_exists(data_in=&data_in, var_in=&cat_var_in) %then %return;
		%if ^%variable_is_numeric(data_in=&data_in,var_in=&cat_var_in) %then %return;	
		%local distinct_cat_var_in_levels;
		proc sql noprint;
			select count(distinct &cat_var_in) 
				   into: distinct_cat_var_in_levels trimmed
			from &data_in;
		quit;
	%end;

	proc sort data=&data_in;
		by %subgroups %by_vars
			%do i=1 %to &nested_vars_size;
				_order&i._ &&nested_var&i
			%end;
			&cat_var_in;
	run;

	%let random=V%sysfunc(rand(integer, 1, 5E6), hex8.);

	data gml.prep;
		set &data_in;
		by %subgroups %by_vars 
			%do i=1 %to &nested_vars_size;
				_order&i._ &&nested_var&i
			%end;;
		&random.row+1; **count the row number;
		%if &by_vars_size or &subgroup_vars_size %then %do;
			if first.
			%if &by_vars_size %then &&by_var&by_vars_size;
			%else %if &subgroup_vars_size %then &&subgroup_var&subgroup_vars_size;
			 then do; **handle subgroups; 
				page+1;
				&random.row=1;
			end;
		%end;
		&random.remaining = (&lines_per_page - &random.row) + 1;
		if
		%if %sysevalf(%superq(cat_var_in)=, boolean) %then &random.row = &lines_per_page;
		%else last.&&nested_var&nested_vars_size and &random.remaining < &distinct_cat_var_in_levels;
			then do; 
			output; **initial Output;
			page+1;
			%do i=1 %to %eval(&nested_vars_size - %sysevalf(%superq(cat_var_in)=, boolean));
				if ^last.&&nested_var&i then do; 
					col1=trim(&&nested_var&i)!!" &continuedlabel";
					&random.row=&i;
					call missing (of &random.dummy %do j=1 %to &clear_vars_size;
														&&clear_var&j
												   %end;);
					output;
				end;
			%end;
			else &random.row=0; **should remove;
		end;
		else output; **original row;
		drop &random:;
	run;

	data &data_out;
		set gml.prep;
		page+1;
	run;

%mend page_break_nested;
