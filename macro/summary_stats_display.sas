/*
*****************************************************************************************************************
Project		 : Open TLF
SAS file name: summary_stats_display.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get population counts from a dataset. Typically ADSL.
Author: Mazi Ntintelo
Creation Date: 2023-06-30
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro summary_stats_display(data_in=
							,data_out=
							,vars_in=
							,display_template=%str({N}#{Mean} ({Stddev})#{Min}, {Max}) 
							);
	%local array_vars
		   stats_size
		   position
		   id
		   stop
		   length
		   start
		   text
		   i
		   j
		   macro_name
		   random
		   vars_size;

	%let macro_name = &sysmacroname;

	/****************************************/
	/**************Validation****************/
	/****************************************/

	%if %required_parameter_is_null(parameter=data_in) %then %return;							
	%if %required_parameter_is_null(parameter=data_out) %then %return;
	%if %required_parameter_is_null(parameter=vars_in) %then %return;  
	%if %required_parameter_is_null(parameter=display_template) %then %return;
	%if %dataset_exists(data_in=&data_in) %then %return;
	%if %dataset_name_is_valid(data_in=&data_out) %then %return;

	%let vars_size=%argument_list_size(argument_list=&vars_in);
	%do i=1 %to &vars_size;
		%local var&i;
		%let var&i=%scan(&vars_in, &i, #);
	%end;

	%let id = %sysfunc(prxparse(%str(m/\{\w+\}/oi)));
	%let stats_size=0;
	%do i=1 %to %argument_list_size(argument_list=&display_template);
		%let text=%qscan(&display_template, &i, #);
		%let position=0;
		%let start=1;
		%let stop=%length(&text);
		%let position=0;
		%let length=0;
		%syscall prxnext(id, start, stop, text, position, length);
		%do %while(&position);
			%let stats_size = %eval(&stats_size + 1);
			%local stats&stats_size;
			%let stats&stats_size = %substr(&text, %eval(&position + 1), %eval(&length - 2));
			%syscall prxnext(id, start, stop, text, position, length);
		%end;
	%end;

	%if ^&stats_size %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] No statistics found in display template;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Please ensure that statistics are enclosed in curly braces {};
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;
	
	%let array_vars=;
	%do i=1 %to &vars_size;
		%do j=1 %to &stats_size;
			%let array_vars=&array_vars &&var&i.._&&stats&j;
			%if %variable_exists(data_in=&data_in, varIn=&&var&i.._&&stats&j) %then %return;
		%end;
	%end;

	%let random = V%sysfunc(rand(integer, 1, 5E6), hex8.);

	data &data_out;
		set &data_in;
		length col1 stats &random.temp &random.frag variable $200;
		retain &random.template "&display_template";
		array &random.labels [&stats_size] $200 _temporary_ (%do i=1 %to &stats_size;
																"&&stats&i"
															%end;);
		array &random.stats [&vars_size, &stats_size] &array_vars;
		do &random.i=1 to dim1(&random.stats); 
			do &random.j=1 to dim2(&random.stats); 
				call symputx(&random.labels[&random.j], &random.stats[&random.i, &random.j], 'l');
			end;
			do &random.j=1 to countw(&random.template, '#');
				variable=scan(vname(&random.stats[&random.i, 1]), 1, '_');
				&random.frag=scan(&random.template, &random.j, '#');
				&random.temp=compress(tranwrd(&random.frag, '{', '&'), '}');
				col1=compress(&random.frag, '{}');
				stats=resolve(&random.temp);
				_order1_=&random.j;
				output;
			end;
		end;
		drop &random:;
	run;
%mend summary_stats_display;