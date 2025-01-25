/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: sort_nested.sas
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

%macro sort_nested(data_in=
				  ,data_out=
				  ,by_vars_in=
				  ,subgroup_vars_in=
				  ,nested_vars_in=
				  ,nested_vars_sort_order=
				  ,nested_vars_sort_direction=
				  ,nested_frequency_sort_vars_in= 
			     );

	%local
	    i
		j
		operator
		macro_name
		subgroup_vars_size
		nested_vars_sort_order_size
		numeric_sort_order_vars_size
		nested_vars_sort_direction_size
		nested_frequency_sort_vars_size
		by_vars_size
		nested_vars_size;	
		
	/****************************************/
	/**************Validation****************/
	/****************************************/

	%let macro_name = &sysmacroname;	
	%if %required_parameter_is_null(parameter=data_in) %then %return;
	%if %required_parameter_is_null(parameter=data_out) %then %return; 
	%if %required_parameter_is_null(parameter=nested_vars_in) %then %return;
	%if %required_parameter_is_null(parameter=nested_vars_sort_order) %then %return;	
	%if %required_parameter_is_null(parameter=nested_vars_sort_direction) %then %return;		
	%if ^%library_exists(libref=gml) %then %return;
	%if ^%dataset_exists(data_in=&data_in) %then %return;
	%if ^%dataset_name_is_valid(data_in=&data_out) %then %return;	
	%if ^%variable_exists(data_in=&data_in, var_in=nested_var_level) %then %return;
	%if ^%variable_is_numeric(data_in=&data_in,var_in=nested_var_level) %then %return;
	%if ^%variable_exists(data_in=&data_in, var_in=_section_) %then %return;
	%if ^%variable_is_numeric(data_in=&data_in,var_in=_section_) %then %return;

	%let subgroup_vars_size=%argument_list_size(argument_list=&subgroup_vars_in);
	%let nested_vars_size=%argument_list_size(argument_list=&nested_vars_in);
	%let nested_vars_sort_order_size=%argument_list_size(argument_list=&nested_vars_sort_order);
	%let nested_vars_sort_direction_size=%argument_list_size(argument_list=&nested_vars_sort_direction);
	%let nested_frequency_sort_vars_size=%argument_list_size(argument_list=&nested_frequency_sort_vars_in);
	%let by_vars_size=%argument_list_size(argument_list=&by_vars_in);

	%if &nested_vars_size ne &nested_vars_sort_order_size %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Unbalanced number of entries between nested_vars_in and nested_vars_sort_order;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Number of entries must match;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;
	%if &nested_vars_size ne &nested_vars_sort_direction_size %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Unbalanced number of entries between nested_vars_in and nested_vars_sort_direction;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Number of entries must match;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;
	%let numeric_sort_order_vars_size = 0;
	%do i=1 %to &nested_vars_size;
		%local nested_var&i 
			   sort_order&i
			   sort_direction&i
			   frequency_sort_var&i;
		%let nested_var&i=%scan(&nested_vars_in, &i, #);
		%let sort_order&i=%qlowcase(%qscan(&nested_vars_sort_order, &i, #));
		%let sort_direction&i=%qlowcase(%qscan(&nested_vars_sort_direction, &i, #));
		%let frequency_sort_var&i = %scan(&nested_frequency_sort_vars_in, &i, #);
		%if ^%variable_exists(data_in=&data_in, var_in=&&nested_var&i) %then %return;
		%if ^%variable_exists(data_in=&data_in, var_in=_order&i._) %then %return;
		%if ^%variable_exists(data_in=&data_in,var_in=_order&i._) %then %return;
		%if ^%sysevalf(%superq(frequency_sort_var&i)=, boolean) %then %do;
			%if ^%variable_exists(data_in=&data_in, var_in=&&frequency_sort_var&i) %then %return;
			%if ^%variable_is_numeric(data_in=&data_in,var_in=&&frequency_sort_var&i) %then %return;
		%end;
		%if &&sort_direction&i = ascending %then %let sort_direction&i=;
		%else %if &&sort_direction&i ne descending %then %do;
			%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Invalid selection for nested_vars_sort_direction parameter.;
			%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Valid values are ASCENDING/DESCENDING case insensitive.;
			%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
			%return;
		%end;
		%if &&sort_order&i = numeric %then %let numeric_sort_order_vars_size=%eval(&numeric_sort_order_vars_size + 1);
		%else %if &&sort_order&i ne alphabetic %then %do;
			%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Invalid selection for nested_vars_sort_order parameter.;
			%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Valid values are NUMERIC/ALPHABETIC case insensitive.;
			%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
			%return;
		%end;
	%end;
	%if &numeric_sort_order_vars_size ne &nested_frequency_sort_vars_size %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] &numeric_sort_order_vars_size nested levels are to be sorted numerically, yet only &nested_frequency_sort_vars_size numeric sort variable is given ;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Number of numeric sorting levels must match with number of numeric sorting variables;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		%return;
	%end;
	%do i=1 %to &subgroup_vars_size;
		%local subgroup_var&i;
		%let subgroup_var&i=%scan(&subgroup_vars_in, &i, #);
		%if ^%variable_exists(data_in=&data_in, var_in=&&subgroup_var&i) %then %return;
	%end;
	%do i=1 %to &by_vars_size;
		%local by_var&i;
	%end;
	
	%if ^%by_vars_are_valid %then %return;

	%do i=1 %to &nested_vars_size;

		proc sql;
			create table gml.aggregated&i as 
				select count(*) as dummy
					   %if &&sort_order&i = numeric %then %do;
						 ,sum(&&frequency_sort_var&i) as &&frequency_sort_var&i
					   %end;
					   %do j=1 %to &i;
							,&&nested_var&j
					   %end;
					   %do j=1 %to &subgroup_vars_size;
							,&&subgroup_var&j
					   %end;
					   %do j=1 %to &by_vars_size;
							,&&by_var&j
					   %end;
				from &data_in
				where nested_var_level=&i
				group by nested_var_level
						 %do j=1 %to &i;
							,&&nested_var&j
						 %end;
						 %do j=1 %to &subgroup_vars_size;
							,&&subgroup_var&j
						 %end;
						 %do j=1 %to &by_vars_size;
							,&&by_var&j
						 %end;;	
		quit;

		proc sort data=gml.aggregated&i
				  out=gml.level&i.sorted
				  (keep=%subgroups %by_vars 
					%do j=1 %to &i;
						&&nested_var&j
					%end;
					%if &&sort_order&i = numeric %then &&frequency_sort_var&i;
					);
			by %subgroups %by_vars 
				%do j=1 %to %eval(&i - 1);
					&&nested_var&j
				%end;
				&&sort_direction&i
				%if &&sort_order&i = numeric %then &&frequency_sort_var&i;
				&&nested_var&i;
		run;

		data gml.level&i.;
			set gml.level&i.sorted;
			by %subgroups %by_vars 
				%do j=1 %to %eval(&i - 1);
					&&nested_var&j
				%end;
				&&sort_direction&i
				%if &&sort_order&i = numeric %then &&frequency_sort_var&i;
				&&nested_var&i;
			%do j=1 %to %eval(&i - 1);
				if first.&&nested_var&j then _order&i._= 0;
			%end;
			_order&i._ + 1;
		run;

		proc sql;
			update &data_in a
				set _order&i._ = (select _order&i._  from gml.level&i. b where 
										%do j=1 %to &subgroup_vars_size;
											&operator a.subgroup_var&j = b.subgroup_var&j
											%let operator=and;
										%end;
										%let operator=;
										%do j=1 %to &by_vars_size;
											&operator a.by_var&j = b.by_var&j
											%let operator=and;
										%end;
										%let operator=;
										%do j=1 %to &i;
											&operator a.&&nested_var&j=b.&&nested_var&j
											%let operator=and;
										%end;
								 )
			;
		quit;
	%end;

	proc sort data=&data_in out=&data_out;
		by _section_
			%do i=1 %to &nested_vars_size;
				_order&i._ &&nested_var&i
			%end;;
	run;

%mend sort_nested;    